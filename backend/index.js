// IMPORTS
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
const PORT = 3000;

// MIDDLEWARE
app.use(cors());
app.use(express.json());

// CONEXIÓN A MYSQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'MYSQLDIEGO', // <--- TU CONTRASEÑA
  database: 'edutrack'
});

db.connect((err) => {
  if (err) {
    console.error('Error al conectar a la DB:', err);
  } else {
    console.log(' Conectado a la base de datos MySQL (EduTrack Final)');
  }
});

// ================= FUNCIÓN AUXILIAR =================
function crearNotificacion(uid, titulo, mensaje) {
    const sql = 'INSERT INTO notificaciones (usuario_id, titulo, mensaje, fecha) VALUES (?, ?, ?, NOW())';
    db.query(sql, [uid, titulo, mensaje], (err) => {
        if (err) console.error("Error creando notificación:", err);
        else console.log(`🔔 Notificación enviada al usuario ${uid}: ${titulo}`);
    });
}

// ================= RUTAS PRINCIPALES =================

// 1. OBTENER GRUPOS (CLASES)
app.get('/grupos', (req, res) => {
    const { profesor_id } = req.query; 

    let sql = `
        SELECT mg.id, g.id as grupo_id, g.nombre, m.nombre as materia 
        FROM materias_grupos mg
        JOIN grupos g ON mg.grupo_id = g.id
        JOIN materias m ON mg.materia_id = m.id
    `;
    
    if (profesor_id) {
        sql += ` WHERE mg.profesor_id = ${db.escape(profesor_id)}`;
    }
    
    sql += ` ORDER BY g.nombre ASC`;
    
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results); 
    });
});

// 2. OBTENER ALUMNOS DE UNA CLASE
app.get('/grupos/:clase_id/alumnos', (req, res) => {
    const { clase_id } = req.params;
    const sql = `
        SELECT u.id, u.nombre, u.email as correo 
        FROM usuarios u
        JOIN alumnos_grupos ag ON u.id = ag.alumno_id
        WHERE ag.grupo_id = (SELECT grupo_id FROM materias_grupos WHERE id = ?) 
        AND u.rol = 'alumno'
    `;
    db.query(sql, [clase_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// 3. OBTENER CALIFICACIONES
app.get('/calificaciones', (req, res) => {
    const { alumno_id, grupo_id } = req.query; 
    const sql = `
        SELECT calificacion FROM calificaciones_finales 
        WHERE alumno_id = ? 
        AND materia_id = (SELECT materia_id FROM materias_grupos WHERE id = ?)
    `;
    db.query(sql, [alumno_id, grupo_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// 4. GUARDAR CALIFICACIÓN Y NOTIFICAR
app.post('/calificaciones', (req, res) => {
    const { alumno_id, grupo_id, calificacion } = req.body; 

    if (!alumno_id || !grupo_id || calificacion === undefined) {
        return res.status(400).json({ error: 'Faltan datos' });
    }

    // 1. Obtener el ID real de la materia y SU NOMBRE para la notificación
    const findMateriaSql = `
        SELECT m.id, m.nombre 
        FROM materias_grupos mg 
        JOIN materias m ON mg.materia_id = m.id 
        WHERE mg.id = ?
    `;
    
    db.query(findMateriaSql, [grupo_id], (err, results) => {
        if (err || results.length === 0) return res.status(500).json({ error: 'No se encontró la materia asociada' });
        
        const realMateriaId = results[0].id;
        const nombreMateria = results[0].nombre; // ej. "Matemáticas"

        const checkSql = 'SELECT id, calificacion FROM calificaciones_finales WHERE alumno_id = ? AND materia_id = ?';
        
        db.query(checkSql, [alumno_id, realMateriaId], (err, gradeResults) => {
            if (err) return res.status(500).json({ error: err.message });

            // MENSAJE PERSONALIZADO SI ES REPROBATORIA
            const esReprobatoria = parseFloat(calificacion) < 7.0;
            let tituloNotif = 'Nueva Calificación';
            let msgNotif = `Tienes una nueva calificación en ${nombreMateria}: ${calificacion}.`;

            if (esReprobatoria) {
                tituloNotif = 'Alerta Académica';
                msgNotif = `¡Atención! Has obtenido un ${calificacion} en ${nombreMateria}. Esta calificación es reprobatoria.`;
            }

            if (gradeResults.length > 0) {
                // ACTUALIZAR
                const oldGrade = gradeResults[0].calificacion;
                const registroId = gradeResults[0].id;
                const updateSql = 'UPDATE calificaciones_finales SET calificacion = ?, fecha_registro = NOW() WHERE id = ?';
                
                db.query(updateSql, [calificacion, registroId], (err) => {
                    if (err) return res.status(500).json({ error: err.message });

                    if (oldGrade != calificacion) {
                        // Si cambió la nota, avisamos del cambio
                        let tituloCambio = 'Calificación Actualizada';
                        let msgCambio = `Tu nota en ${nombreMateria} cambió de ${oldGrade} a ${calificacion}.`;
                        
                        if (esReprobatoria) {
                            tituloCambio = '⚠️ Alerta: Nota Reprobatoria';
                            msgCambio += ' Ten cuidado, estás en riesgo de reprobar.';
                        }
                        crearNotificacion(alumno_id, tituloCambio, msgCambio);
                    }
                    res.json({ message: 'Actualizado correctamente' });
                });

            } else {
                // INSERTAR NUEVA
                const insertSql = 'INSERT INTO calificaciones_finales (alumno_id, materia_id, calificacion, fecha_registro) VALUES (?, ?, ?, NOW())';
                db.query(insertSql, [alumno_id, realMateriaId, calificacion], (err, result) => {
                    if (err) return res.status(500).json({ error: err.message });

                    // Creamos la notificación con el nombre de la materia
                    crearNotificacion(alumno_id, tituloNotif, msgNotif);
                    res.json({ message: 'Guardado correctamente', id: result.insertId });
                });
            }
        });
    });
});

// 5. NOTIFICACIONES
app.get('/notificaciones/:usuario_id', (req, res) => {
    const { usuario_id } = req.params;
    const sql = 'SELECT * FROM notificaciones WHERE usuario_id = ? ORDER BY fecha DESC';
    db.query(sql, [usuario_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// 6. REGISTRO
app.post('/register', (req, res) => {
    const { nombre, correo, contrasena, tipo_usuario } = req.body;
    let rol = tipo_usuario.toLowerCase();
    if (rol === 'maestro') rol = 'profesor';

    const sql = 'INSERT INTO usuarios (nombre, email, password, rol) VALUES (?, ?, ?, ?)';
    db.query(sql, [nombre, correo, contrasena, rol], (err, result) => {
        if (err) {
             if (err.code === 'ER_DUP_ENTRY') return res.status(400).json({ error: 'El correo ya está registrado' });
             return res.status(500).json({ error: err.message });
        }
        // Notificación de bienvenida
        crearNotificacion(result.insertId, 'Bienvenido a EduTrack', 'Tu cuenta ha sido creada exitosamente.');
        res.json({ message: 'Registrado exitosamente', id: result.insertId });
    });
});

app.post('/login', (req, res) => {
    // YA NO pedimos 'tipo_usuario' en el body
    const { correo, contrasena } = req.body;

    // Buscamos solo por email y password
    const sql = 'SELECT * FROM usuarios WHERE email = ? AND password = ?';
    
    db.query(sql, [correo, contrasena], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        
        if (results.length > 0) {
            const u = results[0];
            // Devolvemos el rol que está en la base de datos
            res.json({ 
                message: 'Login OK', 
                usuario: { 
                    id: u.id, 
                    nombre: u.nombre, 
                    rol: u.rol 
                } 
            });
        } else {
            res.status(401).json({ error: 'Credenciales incorrectas' });
        }
    });
});

// 8. BUSCAR ALUMNOS
app.get('/alumnos/buscar', (req, res) => {
    const { q } = req.query; 
    const sql = `SELECT id, nombre, email as correo FROM usuarios WHERE rol = 'alumno' AND (nombre LIKE ? OR email LIKE ?) LIMIT 5`;
    const query = `%${q}%`;
    db.query(sql, [query, query], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// 9. AGREGAR ALUMNO A UN GRUPO (CON NOTIFICACIÓN)
app.post('/grupos/agregar_alumno', (req, res) => {
    const { alumno_id, grupo_id } = req.body;
    if (!alumno_id || !grupo_id) return res.status(400).json({ error: 'Faltan datos' });

    // 1. Obtener nombre del grupo para la notificación
    db.query('SELECT nombre FROM grupos WHERE id = ?', [grupo_id], (err, gRes) => {
        const nombreGrupo = gRes.length > 0 ? gRes[0].nombre : 'un grupo';

        const sql = `
            INSERT INTO alumnos_grupos (alumno_id, grupo_id) 
            VALUES (?, ?) 
            ON DUPLICATE KEY UPDATE grupo_id = VALUES(grupo_id), fecha_inscripcion = NOW()
        `;
        db.query(sql, [alumno_id, grupo_id], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            
            const accion = result.affectedRows === 1 ? 'inscrito' : 'movido';
            
            // Notificar al alumno
            crearNotificacion(alumno_id, 'Asignación de Grupo', `Has sido ${accion} al grupo ${nombreGrupo}.`);
            
            res.json({ message: `Alumno ${accion} correctamente al grupo` });
        });
    });
});

// 10. GRUPOS DISPONIBLES
app.get('/grupos_disponibles', (req, res) => {
    const sql = 'SELECT id, nombre FROM grupos ORDER BY nombre';
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// 11. CREAR MATERIA
app.post('/clases/crear', (req, res) => {
    const { grupo_id, nombre_materia, profesor_id } = req.body; 
    if (!grupo_id || !nombre_materia) return res.status(400).json({ error: 'Faltan datos' });

    const buscarMateriaSql = 'SELECT id FROM materias WHERE nombre = ?';
    db.query(buscarMateriaSql, [nombre_materia], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        let materiaId;
        const crearRelacion = (mId) => {
            const insertClaseSql = 'INSERT INTO materias_grupos (grupo_id, materia_id, profesor_id) VALUES (?, ?, ?)';
            db.query(insertClaseSql, [grupo_id, mId, profesor_id || null], (err, result) => {
                if (err) return res.status(500).json({ error: 'Error creando clase' });
                res.json({ message: 'Clase creada exitosamente', id: result.insertId });
            });
        };

        if (results.length > 0) {
            materiaId = results[0].id;
            crearRelacion(materiaId);
        } else {
            const crearMateriaSql = 'INSERT INTO materias (nombre, codigo) VALUES (?, ?)';
            const codigo = nombre_materia.substring(0,3).toUpperCase() + Math.floor(Math.random() * 1000);
            db.query(crearMateriaSql, [nombre_materia, codigo], (err, result) => {
                if (err) return res.status(500).json({ error: err.message });
                materiaId = result.insertId;
                crearRelacion(materiaId);
            });
        }
    });
});

// 12. ELIMINAR ALUMNO (CON NOTIFICACIÓN)
app.post('/grupos/eliminar_alumno', (req, res) => {
    const { alumno_id, grupo_id } = req.body;
    if (!alumno_id || !grupo_id) return res.status(400).json({ error: 'Faltan datos' });

    // Obtener nombre del grupo para notificar antes de borrar
    db.query('SELECT nombre FROM grupos WHERE id = ?', [grupo_id], (err, gRes) => {
        const nombreGrupo = gRes.length > 0 ? gRes[0].nombre : 'un grupo';

        const sql = 'DELETE FROM alumnos_grupos WHERE alumno_id = ? AND grupo_id = ?';
        db.query(sql, [alumno_id, grupo_id], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            
            // Notificar la baja
            crearNotificacion(alumno_id, 'Baja de Grupo', `Has sido dado de baja del grupo ${nombreGrupo}. Contacta a tu profesor si es un error.`);
            
            res.json({ message: 'Alumno eliminado del grupo' });
        });
    });
});

// 13. VERIFICAR GRUPO
app.get('/alumnos/:id/grupo', (req, res) => {
    const { id } = req.params;
    const sql = `SELECT g.id, g.nombre FROM alumnos_grupos ag JOIN grupos g ON ag.grupo_id = g.id WHERE ag.alumno_id = ?`;
    db.query(sql, [id], (err, results) => {
        if (err) return res.status(500).json({ error: 'DB Error' }); 
        if (results.length > 0) {
            res.json({ enrolled: true, group_id: results[0].id, group_name: results[0].nombre });
        } else {
            res.json({ enrolled: false });
        }
    });
});

// 14. STATS PROFESOR
app.get('/profesor/:id/stats', (req, res) => {
    const { id } = req.params;
    const sqlGroups = `SELECT COUNT(DISTINCT grupo_id) as total_grupos FROM materias_grupos WHERE profesor_id = ?`;
    const sqlAlumnos = `SELECT COUNT(DISTINCT ag.alumno_id) AS total_alumnos FROM alumnos_grupos ag JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id WHERE mg.profesor_id = ?`;

    db.query(sqlGroups, [id], (err, resGroups) => {
        if (err) return res.json({ grupos: 0, alumnos: 0 });
        db.query(sqlAlumnos, [id], (err, resAlumnos) => {
            if (err) return res.json({ grupos: 0, alumnos: 0 });
            res.json({ grupos: resGroups[0].total_grupos, alumnos: resAlumnos[0].total_alumnos });
        });
    });
});

// 15. DASHBOARD
app.get('/dashboard/:id', (req, res) => {
    const { id } = req.params;
    const sqlAlumno = 'SELECT nombre FROM usuarios WHERE id = ? AND rol = "alumno"';
    const sqlMaterias = `
        SELECT m.nombre as materia, cf.calificacion 
        FROM alumnos_grupos ag
        JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id
        JOIN materias m ON mg.materia_id = m.id
        LEFT JOIN calificaciones_finales cf ON cf.materia_id = mg.materia_id AND cf.alumno_id = ag.alumno_id
        WHERE ag.alumno_id = ?
    `;
    db.query(sqlAlumno, [id], (err, userResults) => {
        if (err || userResults.length === 0) return res.status(404).json({ error: 'Alumno no encontrado' });
        const alumno = userResults[0];
        db.query(sqlMaterias, [id], (err, matResults) => {
            if (err) return res.status(500).json({ error: err.message });
            let total = 0; let count = 0;
            const subjects = matResults.map(row => {
                let calif = null; let estado = 'Pendiente';
                if (row.calificacion !== null) {
                    calif = parseFloat(row.calificacion);
                    total += calif; count++;
                    estado = calif >= 7.0 ? 'Aprobada' : 'Reprobada';
                }
                return { materia: row.materia, calificacion: calif, estado: estado };
            });
            const avg = count > 0 ? (total / count) : 0.0;
            res.json({ average: parseFloat(avg.toFixed(1)), student: { nombre: alumno.nombre, carrera: 'Software', matricula: id.toString() }, subjects: subjects });
        });
    });
});

// 16. REPORTE SOPORTE
app.post('/reportes_soporte', (req, res) => {
    const { usuario_id, email, mensaje } = req.body;
    db.query('INSERT INTO reportes_soporte (usuario_id, email, mensaje) VALUES (?, ?, ?)', [usuario_id, email, mensaje], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Reporte guardado', id: result.insertId });
    });
});

// 17. HISTORIAL
app.get('/historial_academico/:alumnoId', (req, res) => {
    const { alumnoId } = req.params;
    const sql = `
        SELECT m.nombre, cf.calificacion, g.nombre AS grupo_nombre, u.nombre AS profesor 
        FROM calificaciones_finales cf
        JOIN materias m ON cf.materia_id = m.id
        JOIN materias_grupos mg ON m.id = mg.materia_id
        JOIN grupos g ON mg.grupo_id = g.id
        LEFT JOIN usuarios u ON mg.profesor_id = u.id
        WHERE cf.alumno_id = ? ORDER BY g.nombre, m.nombre
    `;
    db.query(sql, [alumnoId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        const semestres = {};
        results.forEach(row => {
            const sem = row.grupo_nombre || 'Sin Grupo';
            if (!semestres[sem]) semestres[sem] = [];
            semestres[sem].push({ nombre: row.nombre, profesor: row.profesor || 'Desc.', semestre: sem, evaluaciones: [{ nombre: 'Final', peso: 100, calificacion: row.calificacion || 0 }] });
        });
        res.json({ semestres: semestres });
    });
});

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});