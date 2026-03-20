// IMPORTS
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();

function ensureAuxTables() {
    const createActivitiesTableSql = `
        CREATE TABLE IF NOT EXISTS calificaciones_actividades (
            id INT AUTO_INCREMENT PRIMARY KEY,
            alumno_id INT NOT NULL,
            clase_id INT NOT NULL,
            titulo VARCHAR(150) NOT NULL,
            calificacion DECIMAL(4,2) NULL,
            comentario TEXT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_calif_actividades_alumno_clase (alumno_id, clase_id),
            INDEX idx_calif_actividades_clase (clase_id)
        )
    `;

    const createLegacyStudentsTableSql = `
        CREATE TABLE IF NOT EXISTS alumnos (
            id INT PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            matricula VARCHAR(50) NULL
        )
    `;

    db.query(createActivitiesTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla calificaciones_actividades:', err);
        }
    });

    db.query(createLegacyStudentsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla legacy alumnos:', err);
        }
    });
}

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// CONEXIÓN A MYSQL
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

db.connect((err) => {
  if (err) {
    console.error('Error al conectar a la DB:', err);
  } else {
    console.log(' Conectado a la base de datos MySQL (EduTrack Final)');
    ensureAuxTables();
  }
});

// ================= FUNCIÓN AUXILIAR =================
function crearNotificacion(uid, titulo, mensaje) {
    const sql = 'INSERT INTO notificaciones (usuario_id, titulo, mensaje, fecha) VALUES (?, ?, ?, NOW())';
    db.query(sql, [uid, titulo, mensaje], (err) => {
        if (err) console.error("Error creando notificación:", err);
        else console.log(`Notificación enviada al usuario ${uid}: ${titulo}`);
    });
}

function parseNullableGrade(value) {
    if (value === null || value === undefined || value === '') return null;
    const num = Number.parseFloat(value);
    return Number.isFinite(num) ? num : null;
}

function roundGrade(value) {
    if (value === null || value === undefined) return null;
    return Number.parseFloat(Number(value).toFixed(1));
}

function computeAverageGrade(activities) {
    const grades = activities
        .map((activity) => parseNullableGrade(activity.calificacion))
        .filter((grade) => grade !== null);

    if (!grades.length) return null;

    const total = grades.reduce((sum, grade) => sum + grade, 0);
    return roundGrade(total / grades.length);
}

function mapActivityRow(row) {
    let fecha = '';
    if (row.fecha_registro instanceof Date) {
        fecha = row.fecha_registro.toISOString();
    } else if (row.fecha_registro) {
        fecha = String(row.fecha_registro);
    }

    return {
        id: row.id,
        titulo: row.titulo || 'Actividad',
        calificacion: parseNullableGrade(row.calificacion),
        comentario: row.comentario || '',
        fecha: fecha,
        tipo: row.tipo || 'actividad'
    };
}

function groupActivitiesByClass(rows) {
    const map = {};

    for (const row of rows) {
        if (!map[row.clase_id]) {
            map[row.clase_id] = [];
        }
        map[row.clase_id].push(mapActivityRow(row));
    }

    return map;
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

// 1B) OBTENER MIS GRUPOS AGRUPADOS (UN GRUPO, MUCHAS MATERIAS)
app.get('/mis_grupos', (req, res) => {
  const { profesor_id } = req.query;

  if (!profesor_id) {
    return res.status(400).json({ error: 'Falta profesor_id' });
  }

  const sql = `
    SELECT 
      g.id AS grupo_id,
      g.nombre AS grupo_nombre,
      mg.id AS clase_id,
      m.id AS materia_id,
      m.nombre AS materia_nombre,
      (SELECT COUNT(*) 
       FROM alumnos_grupos ag 
       WHERE ag.grupo_id = g.id) AS total_alumnos
    FROM materias_grupos mg
    JOIN grupos g ON mg.grupo_id = g.id
    JOIN materias m ON mg.materia_id = m.id
    WHERE mg.profesor_id = ?
    ORDER BY g.nombre ASC, m.nombre ASC
  `;

  db.query(sql, [profesor_id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });

    // Agrupar: { grupo_id -> {grupo_nombre, total_alumnos, materias[] } }
    const map = {};
    for (const r of rows) {
      if (!map[r.grupo_id]) {
        map[r.grupo_id] = {
          grupo_id: r.grupo_id,
          nombre: r.grupo_nombre,
          total_alumnos: r.total_alumnos || 0,
          materias: []
        };
      }
      map[r.grupo_id].materias.push({
        clase_id: r.clase_id,          // ✅ mg.id (este es el que ocupa tu app)
        materia_id: r.materia_id,
        materia: r.materia_nombre
      });
    }

    res.json(Object.values(map));
  });
});

// 2. OBTENER ALUMNOS POR CLASE
// Recibe clase_id = materias_grupos.id y resuelve el grupo físico asociado.
app.get('/grupos/:clase_id/alumnos', (req, res) => {
    const { clase_id } = req.params;

    const sql = `
        SELECT DISTINCT
            COALESCE(u.id, a.id) AS id,
            COALESCE(u.nombre, a.nombre) AS nombre,
            COALESCE(u.email, CONCAT('alumno', a.id, '@legacy.local')) AS correo
        FROM materias_grupos mg
        JOIN alumnos_grupos ag ON ag.grupo_id = mg.grupo_id
        LEFT JOIN usuarios u ON u.id = ag.alumno_id AND u.rol = 'alumno'
        LEFT JOIN alumnos a ON a.id = ag.alumno_id
        WHERE mg.id = ?
          AND (u.id IS NOT NULL OR a.id IS NOT NULL)
        ORDER BY COALESCE(u.nombre, a.nombre) ASC
    `;

    db.query(sql, [clase_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

app.get('/grupos/:clase_id/calificaciones_resumen', (req, res) => {
    const { clase_id } = req.params;

    const sql = `
        SELECT
            COALESCE(u.id, a.id) AS id,
            COALESCE(u.nombre, a.nombre) AS nombre,
            COALESCE(u.email, CONCAT('alumno', a.id, '@legacy.local')) AS correo,
            cf.calificacion AS calificacion_final,
            COALESCE(act.total_actividades, 0) AS total_actividades,
            act.promedio_actividades,
            act.ultimo_comentario
        FROM materias_grupos mg
        JOIN alumnos_grupos ag ON ag.grupo_id = mg.grupo_id
        LEFT JOIN usuarios u ON u.id = ag.alumno_id AND u.rol = 'alumno'
        LEFT JOIN alumnos a ON a.id = ag.alumno_id
        LEFT JOIN calificaciones_finales cf
            ON cf.alumno_id = ag.alumno_id
            AND cf.materia_id = mg.materia_id
        LEFT JOIN (
            SELECT
                clase_id,
                alumno_id,
                COUNT(*) AS total_actividades,
                ROUND(AVG(CASE WHEN calificacion IS NOT NULL THEN calificacion END), 2) AS promedio_actividades,
                SUBSTRING_INDEX(
                    GROUP_CONCAT(NULLIF(TRIM(comentario), '') ORDER BY fecha_registro DESC SEPARATOR '|||'),
                    '|||',
                    1
                ) AS ultimo_comentario
            FROM calificaciones_actividades
            GROUP BY clase_id, alumno_id
        ) act
            ON act.clase_id = mg.id
            AND act.alumno_id = ag.alumno_id
        WHERE mg.id = ?
          AND (u.id IS NOT NULL OR a.id IS NOT NULL)
        ORDER BY COALESCE(u.nombre, a.nombre) ASC
    `;

    db.query(sql, [clase_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        const payload = results.map((row) => ({
            id: row.id,
            nombre: row.nombre,
            correo: row.correo,
            calificacion_final: parseNullableGrade(row.calificacion_final),
            total_actividades: Number(row.total_actividades || 0),
            promedio_actividades: parseNullableGrade(row.promedio_actividades),
            ultimo_comentario: row.ultimo_comentario || ''
        }));

        res.json(payload);
    });
});

app.get('/calificaciones_actividades', (req, res) => {
    const { alumno_id, grupo_id } = req.query;

    if (!alumno_id || !grupo_id) {
        return res.status(400).json({ error: 'Faltan alumno_id o grupo_id' });
    }

    const sql = `
        SELECT id, alumno_id, clase_id, titulo, calificacion, comentario, fecha_registro
        FROM calificaciones_actividades
        WHERE alumno_id = ?
          AND clase_id = ?
        ORDER BY fecha_registro DESC, id DESC
    `;

    db.query(sql, [alumno_id, grupo_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results.map(mapActivityRow));
    });
});

app.post('/calificaciones_actividades', (req, res) => {
    const { alumno_id, grupo_id, titulo, calificacion, comentario } = req.body;

    const tituloLimpio = String(titulo || '').trim() || 'Actividad';
    const comentarioLimpio = String(comentario || '').trim();
    const calificacionNumero = parseNullableGrade(calificacion);

    if (!alumno_id || !grupo_id) {
        return res.status(400).json({ error: 'Faltan alumno_id o grupo_id' });
    }

    if (calificacionNumero === null && !comentarioLimpio) {
        return res.status(400).json({ error: 'Agrega una calificación o un comentario' });
    }

    if (calificacionNumero !== null && (calificacionNumero < 0 || calificacionNumero > 10)) {
        return res.status(400).json({ error: 'La calificación debe estar entre 0 y 10' });
    }

    const materiaSql = `
        SELECT m.nombre AS materia_nombre
        FROM materias_grupos mg
        JOIN materias m ON mg.materia_id = m.id
        WHERE mg.id = ?
        LIMIT 1
    `;

    db.query(materiaSql, [grupo_id], (err, materiaRows) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!materiaRows.length) return res.status(404).json({ error: 'Clase no encontrada' });

        const insertSql = `
            INSERT INTO calificaciones_actividades (
                alumno_id,
                clase_id,
                titulo,
                calificacion,
                comentario,
                fecha_registro,
                fecha_actualizacion
            )
            VALUES (?, ?, ?, ?, ?, NOW(), NOW())
        `;

        db.query(
            insertSql,
            [alumno_id, grupo_id, tituloLimpio, calificacionNumero, comentarioLimpio || null],
            (insertErr, result) => {
                if (insertErr) return res.status(500).json({ error: insertErr.message });

                const materiaNombre = materiaRows[0].materia_nombre || 'tu materia';
                const partes = [];

                if (calificacionNumero !== null) {
                    partes.push(`${tituloLimpio}: ${calificacionNumero}`);
                }

                if (comentarioLimpio) {
                    const resumen = comentarioLimpio.length > 90
                        ? `${comentarioLimpio.slice(0, 87)}...`
                        : comentarioLimpio;
                    partes.push(`Comentario: ${resumen}`);
                }

                crearNotificacion(
                    alumno_id,
                    'Nueva actividad registrada',
                    `${materiaNombre} • ${partes.join(' | ')}`
                );

                res.json({
                    message: 'Actividad guardada',
                    id: result.insertId
                });
            }
        );
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

// 6. REGISTRO ACTUALIZADO PARA TUTOR (REQUERIMIENTO 3.1)
app.post('/register', (req, res) => {
    const { nombre, email, password, rol, matricula_hijo } = req.body;

    // Si el que se registra es un tutor, verificamos la matrícula del hijo primero
    if (rol === 'tutor') {
        const checkSql = 'SELECT id FROM usuarios WHERE id = ? AND rol = "alumno"';
        db.query(checkSql, [matricula_hijo], (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            
            if (results.length === 0) {
                return res.status(400).json({ error: 'Seguridad: La matrícula del hijo no existe.' });
            }

            // Si existe, procedemos a insertar al tutor
            const sqlInsert = 'INSERT INTO usuarios (nombre, email, password, rol) VALUES (?, ?, ?, ?)';
            db.query(sqlInsert, [nombre, email, password, rol], (err, result) => {
                if (err) return res.status(500).json({ error: err.message });
                crearNotificacion(result.insertId, 'Bienvenido Tutor', 'Tu cuenta ha sido vinculada correctamente.');
                res.status(201).json({ message: 'Tutor registrado exitosamente', id: result.insertId });
            });
        });
    } else {
        // Registro normal para otros roles
        const sql = 'INSERT INTO usuarios (nombre, email, password, rol) VALUES (?, ?, ?, ?)';
        db.query(sql, [nombre, email, password, rol], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.status(201).json({ message: 'Registrado exitosamente', id: result.insertId });
        });
    }
});

// Mantén el resto de tus rutas (login, grupos, etc.) igual que antes...
app.post('/login', (req, res) => {
    const { correo, contrasena } = req.body;
    const sql = 'SELECT * FROM usuarios WHERE email = ? AND password = ?';
    db.query(sql, [correo, contrasena], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length > 0) {
            const u = results[0];
            res.json({ message: 'Login OK', usuario: { id: u.id, nombre: u.nombre, rol: u.rol } });
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
        SELECT
            mg.id AS clase_id,
            m.nombre AS materia,
            cf.calificacion AS calificacion_final
        FROM alumnos_grupos ag
        JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id
        JOIN materias m ON mg.materia_id = m.id
        LEFT JOIN calificaciones_finales cf ON cf.materia_id = mg.materia_id AND cf.alumno_id = ag.alumno_id
        WHERE ag.alumno_id = ?
        ORDER BY m.nombre
    `;
    const sqlActividades = `
        SELECT
            id,
            clase_id,
            titulo,
            calificacion,
            comentario,
            fecha_registro
        FROM calificaciones_actividades
        WHERE alumno_id = ?
        ORDER BY fecha_registro DESC, id DESC
    `;

    db.query(sqlAlumno, [id], (err, userResults) => {
        if (err || userResults.length === 0) return res.status(404).json({ error: 'Alumno no encontrado' });
        const alumno = userResults[0];

        db.query(sqlMaterias, [id], (err, matResults) => {
            if (err) return res.status(500).json({ error: err.message });

            db.query(sqlActividades, [id], (activitiesErr, activitiesResults) => {
                if (activitiesErr) return res.status(500).json({ error: activitiesErr.message });

                const activitiesByClass = groupActivitiesByClass(activitiesResults);
                let total = 0;
                let count = 0;

                const subjects = matResults.map((row) => {
                    const activities = activitiesByClass[row.clase_id] || [];
                    const finalGrade = parseNullableGrade(row.calificacion_final);
                    const averageActivities = computeAverageGrade(activities);
                    const calif = finalGrade !== null ? finalGrade : averageActivities;

                    let estado = 'Pendiente';
                    if (calif !== null) {
                        total += calif;
                        count++;
                        estado = calif >= 7.0 ? 'Aprobada' : 'Reprobada';
                    }

                    return {
                        clase_id: row.clase_id,
                        materia: row.materia,
                        calificacion: calif,
                        estado: estado,
                        total_actividades: activities.length,
                        actividades: activities.slice(0, 5)
                    };
                });

                const avg = count > 0 ? roundGrade(total / count) : 0.0;
                res.json({
                    average: avg,
                    student: {
                        nombre: alumno.nombre,
                        carrera: 'Software',
                        matricula: id.toString()
                    },
                    subjects: subjects
                });
            });
        });
    });
});

// 16. REPORTE SOPORTE
app.post('/reportes_soporte', (req, res) => {
    const usuarioId = Number.parseInt(req.body.usuario_id, 10);
    const email = String(req.body.email || '').trim();
    const mensaje = String(req.body.mensaje || '').trim();

    if (!email || !mensaje) {
        return res.status(400).json({ error: 'Faltan datos del reporte' });
    }

    db.query('INSERT INTO reportes_soporte (usuario_id, email, mensaje) VALUES (?, ?, ?)', [Number.isNaN(usuarioId) ? 0 : usuarioId, email, mensaje], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Reporte guardado', id: result.insertId });
    });
});

// 17. HISTORIAL
app.get('/historial_academico/:alumnoId', (req, res) => {
    const { alumnoId } = req.params;
    const sqlMaterias = `
        SELECT
            mg.id AS clase_id,
            m.nombre,
            g.nombre AS grupo_nombre,
            u.nombre AS profesor,
            cf.calificacion AS calificacion_final
        FROM alumnos_grupos ag
        JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id
        JOIN materias m ON mg.materia_id = m.id
        JOIN grupos g ON mg.grupo_id = g.id
        LEFT JOIN usuarios u ON mg.profesor_id = u.id
        LEFT JOIN calificaciones_finales cf
            ON cf.materia_id = mg.materia_id
            AND cf.alumno_id = ag.alumno_id
        WHERE ag.alumno_id = ?
        ORDER BY g.nombre, m.nombre
    `;
    const sqlActividades = `
        SELECT
            id,
            clase_id,
            titulo,
            calificacion,
            comentario,
            fecha_registro
        FROM calificaciones_actividades
        WHERE alumno_id = ?
        ORDER BY fecha_registro DESC, id DESC
    `;

    db.query(sqlMaterias, [alumnoId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        db.query(sqlActividades, [alumnoId], (activitiesErr, activityRows) => {
            if (activitiesErr) return res.status(500).json({ error: activitiesErr.message });

            const activitiesByClass = groupActivitiesByClass(activityRows);
            const semestres = {};

            results.forEach((row) => {
                const sem = row.grupo_nombre || 'Sin Grupo';
                const activities = activitiesByClass[row.clase_id] || [];
                const finalGrade = parseNullableGrade(row.calificacion_final);
                const averageActivities = computeAverageGrade(activities);
                const finalToShow = finalGrade !== null
                    ? finalGrade
                    : (averageActivities !== null ? averageActivities : 0);

                if (!semestres[sem]) semestres[sem] = [];

                const evaluaciones = activities.map((activity) => ({
                    nombre: activity.titulo,
                    peso: activities.length ? roundGrade(100 / activities.length) : 0,
                    calificacion: activity.calificacion,
                    comentario: activity.comentario,
                    fecha: activity.fecha,
                    tipo: 'actividad'
                }));

                semestres[sem].push({
                    nombre: row.nombre,
                    profesor: row.profesor || 'Desc.',
                    semestre: sem,
                    calificacion_final: finalToShow,
                    evaluaciones: evaluaciones
                });
            });

            res.json({ semestres: semestres });
        });
    });
});

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
