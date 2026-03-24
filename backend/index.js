// IMPORTS
const express = require('express');
const fs = require('fs');
const mysql = require('mysql2');
const path = require('path');
const cors = require('cors');
require('dotenv').config();

const MAX_REPORT_ATTACHMENT_BYTES = 10 * 1024 * 1024;
const UPLOADS_DIR = path.join(__dirname, 'uploads');
const TUTOR_REPORTS_UPLOAD_DIR = path.join(UPLOADS_DIR, 'reportes_tutor');

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

    const createClassActivitiesSql = `
        CREATE TABLE IF NOT EXISTS actividades_clase (
            id INT AUTO_INCREMENT PRIMARY KEY,
            clase_id INT NOT NULL,
            titulo VARCHAR(150) NOT NULL,
            descripcion TEXT NULL,
            valor DECIMAL(5,2) NOT NULL DEFAULT 1,
            fecha_entrega DATE NULL,
            cuenta_para_final TINYINT(1) NOT NULL DEFAULT 1,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_actividades_clase_clase (clase_id)
        )
    `;

    const createActivityStudentsSql = `
        CREATE TABLE IF NOT EXISTS actividades_alumnos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            actividad_id INT NOT NULL,
            alumno_id INT NOT NULL,
            entregado TINYINT(1) NOT NULL DEFAULT 0,
            calificacion DECIMAL(4,2) NULL,
            comentario TEXT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_actividad_alumno (actividad_id, alumno_id),
            INDEX idx_actividades_alumnos_alumno (alumno_id)
        )
    `;

    const createLegacyStudentsTableSql = `
        CREATE TABLE IF NOT EXISTS alumnos (
            id INT PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            matricula VARCHAR(50) NULL
        )
    `;

    const createTutorStudentsTableSql = `
        CREATE TABLE IF NOT EXISTS tutores_alumnos (
            tutor_id INT NOT NULL PRIMARY KEY,
            alumno_id INT NOT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_tutores_alumnos_alumno (alumno_id)
        )
    `;

    const createTutorReportsTableSql = `
        CREATE TABLE IF NOT EXISTS reportes_tutor (
            id INT AUTO_INCREMENT PRIMARY KEY,
            tutor_id INT NOT NULL,
            alumno_id INT NOT NULL,
            categoria VARCHAR(80) NOT NULL,
            materia VARCHAR(120) NULL,
            titulo VARCHAR(150) NOT NULL,
            mensaje TEXT NOT NULL,
            estado VARCHAR(40) NOT NULL DEFAULT 'Enviado',
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_reportes_tutor_tutor (tutor_id),
            INDEX idx_reportes_tutor_alumno (alumno_id)
        )
    `;

    const createTutorReportAttachmentsTableSql = `
        CREATE TABLE IF NOT EXISTS reportes_tutor_adjuntos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            reporte_id INT NOT NULL UNIQUE,
            nombre_original VARCHAR(255) NOT NULL,
            nombre_archivo VARCHAR(255) NOT NULL,
            mime_type VARCHAR(120) NULL,
            tamano_bytes INT NOT NULL DEFAULT 0,
            ruta_relativa VARCHAR(255) NOT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_reportes_tutor_adjuntos_reporte (reporte_id)
        )
    `;

    const createAttendanceRecordsTableSql = `
        CREATE TABLE IF NOT EXISTS asistencias_registro (
            id INT AUTO_INCREMENT PRIMARY KEY,
            clase_id INT NOT NULL,
            fecha DATE NOT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_asistencia_clase_fecha (clase_id, fecha),
            INDEX idx_asistencia_registro_clase (clase_id),
            INDEX idx_asistencia_registro_fecha (fecha)
        )
    `;

    const createAttendanceDetailsTableSql = `
        CREATE TABLE IF NOT EXISTS asistencias_detalle (
            id INT AUTO_INCREMENT PRIMARY KEY,
            registro_id INT NOT NULL,
            alumno_id INT NOT NULL,
            estado VARCHAR(20) NOT NULL,
            nota TEXT NULL,
            fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_asistencia_registro_alumno (registro_id, alumno_id),
            INDEX idx_asistencia_detalle_registro (registro_id),
            INDEX idx_asistencia_detalle_alumno (alumno_id)
        )
    `;

    const ensureTutorRoleSql = `
        ALTER TABLE usuarios
        MODIFY COLUMN rol ENUM('alumno','profesor','admin','tutor')
        NOT NULL DEFAULT 'alumno'
    `;

    db.query(createActivitiesTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla calificaciones_actividades:', err);
        }
    });

    db.query(createClassActivitiesSql, (err) => {
        if (err) {
            console.error('Error creando tabla actividades_clase:', err);
        }
    });

    db.query(createActivityStudentsSql, (err) => {
        if (err) {
            console.error('Error creando tabla actividades_alumnos:', err);
        }
    });

    db.query(createLegacyStudentsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla legacy alumnos:', err);
        }
    });

    db.query(createTutorStudentsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla tutores_alumnos:', err);
        }
    });

    db.query(createTutorReportsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla reportes_tutor:', err);
        }
    });

    db.query(createTutorReportAttachmentsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla reportes_tutor_adjuntos:', err);
        }
    });

    db.query(createAttendanceRecordsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla asistencias_registro:', err);
        }
    });

    db.query(createAttendanceDetailsTableSql, (err) => {
        if (err) {
            console.error('Error creando tabla asistencias_detalle:', err);
        }
    });

    db.query("SHOW TABLES LIKE 'usuarios'", (err, rows) => {
        if (err) {
            console.error('Error verificando tabla usuarios:', err);
            return;
        }

        if (!rows || !rows.length) {
            return;
        }

        db.query(ensureTutorRoleSql, (alterErr) => {
            if (alterErr) {
                console.error('Error ajustando enum de usuarios.rol:', alterErr);
            }
        });
    });
}

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/uploads', express.static(UPLOADS_DIR));

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
    ensureUploadDirectories();
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

function ensureUploadDirectories() {
    try {
        fs.mkdirSync(TUTOR_REPORTS_UPLOAD_DIR, { recursive: true });
    } catch (error) {
        console.error('Error preparando directorio de adjuntos:', error);
    }
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

function normalizeAttendanceStatus(value) {
    const normalized = String(value || '').trim().toLowerCase();
    if (normalized === 'presente') return 'presente';
    if (normalized === 'retardo') return 'retardo';
    return 'ausente';
}

function formatDateValue(value) {
    if (value instanceof Date) {
        return value.toISOString();
    }

    return String(value || '');
}

function normalizeTextValue(value) {
    return String(value || '').trim();
}

function buildMateriaCode(nombreMateria) {
    const base = normalizeTextValue(nombreMateria)
        .replace(/\s+/g, '')
        .toUpperCase()
        .padEnd(3, 'X')
        .slice(0, 3);
    return `${base}${Math.floor(Math.random() * 1000)}`;
}

function normalizeUploadRelativePath(relativePath) {
    return String(relativePath || '')
        .split(path.sep)
        .join('/')
        .replace(/^\/+/, '');
}

function buildPublicUploadUrl(req, relativePath) {
    const normalizedPath = normalizeUploadRelativePath(relativePath);
    if (!normalizedPath) {
        return '';
    }

    return `${req.protocol}://${req.get('host')}/uploads/${normalizedPath}`;
}

function sanitizeAttachmentBaseName(fileName) {
    const clean = path
        .basename(String(fileName || ''), path.extname(String(fileName || '')))
        .replace(/[^a-zA-Z0-9-_]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .slice(0, 60);

    return clean || 'comprobante';
}

function resolveAttachmentExtension(fileName, mimeType) {
    const ext = path.extname(String(fileName || '')).toLowerCase();
    if (/^\.[a-z0-9]{1,10}$/.test(ext)) {
        return ext;
    }

    const mime = String(mimeType || '').toLowerCase();
    if (mime === 'application/pdf') return '.pdf';
    if (mime === 'image/png') return '.png';
    if (mime === 'image/jpeg') return '.jpg';
    if (mime === 'image/webp') return '.webp';
    return '.bin';
}

function parseTutorReportAttachment(rawAttachment) {
    if (!rawAttachment) {
        return null;
    }

    if (typeof rawAttachment !== 'object') {
        throw new Error('El comprobante adjunto es invalido');
    }

    const fileName = normalizeTextValue(
        rawAttachment.file_name || rawAttachment.fileName
    );
    const mimeType = normalizeTextValue(
        rawAttachment.mime_type || rawAttachment.mimeType
    );
    const rawBase64 = String(
        rawAttachment.base64 || rawAttachment.bytes_base64 || ''
    ).trim();

    if (!fileName || !rawBase64) {
        throw new Error('Faltan datos del comprobante adjunto');
    }

    const base64Payload = rawBase64.includes(',')
        ? rawBase64.split(',').pop()
        : rawBase64;
    const buffer = Buffer.from(base64Payload || '', 'base64');

    if (!buffer.length) {
        throw new Error('No se pudo leer el comprobante adjunto');
    }

    if (buffer.length > MAX_REPORT_ATTACHMENT_BYTES) {
        throw new Error('El comprobante excede el maximo de 10 MB');
    }

    const sizeBytes = Number.parseInt(
        rawAttachment.size_bytes || rawAttachment.sizeBytes,
        10
    );

    return {
        fileName,
        mimeType: mimeType || 'application/octet-stream',
        sizeBytes: Number.isFinite(sizeBytes) && sizeBytes > 0
            ? sizeBytes
            : buffer.length,
        buffer
    };
}

async function saveTutorReportAttachment(reportId, attachment) {
    ensureUploadDirectories();

    const extension = resolveAttachmentExtension(
        attachment.fileName,
        attachment.mimeType
    );
    const baseName = sanitizeAttachmentBaseName(attachment.fileName);
    const storedFileName = `${reportId}_${Date.now()}_${baseName}${extension}`;
    const relativePath = path.join('reportes_tutor', storedFileName);
    const absolutePath = path.join(UPLOADS_DIR, relativePath);

    await fs.promises.writeFile(absolutePath, attachment.buffer);
    await queryAsync(
        `
            INSERT INTO reportes_tutor_adjuntos (
                reporte_id,
                nombre_original,
                nombre_archivo,
                mime_type,
                tamano_bytes,
                ruta_relativa
            )
            VALUES (?, ?, ?, ?, ?, ?)
        `,
        [
            reportId,
            attachment.fileName,
            storedFileName,
            attachment.mimeType,
            attachment.sizeBytes,
            normalizeUploadRelativePath(relativePath)
        ]
    );

    return {
        nombre: attachment.fileName,
        mimeType: attachment.mimeType,
        tamanoBytes: attachment.sizeBytes,
        rutaRelativa: normalizeUploadRelativePath(relativePath)
    };
}

function resolveOrCreateGrupoId({ grupoId, nombreGrupo }, callback) {
    const parsedGrupoId = Number(grupoId);
    if (Number.isInteger(parsedGrupoId) && parsedGrupoId > 0) {
        return callback(null, parsedGrupoId, false);
    }

    const nombreGrupoLimpio = normalizeTextValue(nombreGrupo);
    if (!nombreGrupoLimpio) {
        return callback(new Error('Falta grupo_id o nombre_grupo'));
    }

    const findGroupSql = `
        SELECT id
        FROM grupos
        WHERE LOWER(TRIM(nombre)) = LOWER(?)
        LIMIT 1
    `;

    db.query(findGroupSql, [nombreGrupoLimpio], (findErr, groupRows) => {
        if (findErr) return callback(findErr);

        if (groupRows.length > 0) {
            return callback(null, Number(groupRows[0].id), false);
        }

        db.query("SHOW COLUMNS FROM grupos LIKE 'materia'", (columnsErr, columns) => {
            if (columnsErr) return callback(columnsErr);

            const materiaColumn = columns[0];
            const requiresLegacyMateria =
                !!materiaColumn &&
                materiaColumn.Null === 'NO' &&
                materiaColumn.Default === null;

            const insertSql = requiresLegacyMateria
                ? 'INSERT INTO grupos (nombre, materia) VALUES (?, ?)'
                : 'INSERT INTO grupos (nombre) VALUES (?)';
            const insertParams = requiresLegacyMateria
                ? [nombreGrupoLimpio, 'General']
                : [nombreGrupoLimpio];

            db.query(insertSql, insertParams, (insertErr, insertResult) => {
                if (insertErr) return callback(insertErr);
                callback(null, Number(insertResult.insertId), true);
            });
        });
    });
}

function resolveOrCreateMateriaId(nombreMateria, callback) {
    const nombreMateriaLimpio = normalizeTextValue(nombreMateria);
    if (!nombreMateriaLimpio) {
        return callback(new Error('Falta nombre_materia'));
    }

    const findSubjectSql = `
        SELECT id
        FROM materias
        WHERE LOWER(TRIM(nombre)) = LOWER(?)
        LIMIT 1
    `;

    db.query(findSubjectSql, [nombreMateriaLimpio], (findErr, subjectRows) => {
        if (findErr) return callback(findErr);

        if (subjectRows.length > 0) {
            return callback(null, Number(subjectRows[0].id), false);
        }

        const createSubjectSql = 'INSERT INTO materias (nombre, codigo) VALUES (?, ?)';
        db.query(
            createSubjectSql,
            [nombreMateriaLimpio, buildMateriaCode(nombreMateriaLimpio)],
            (createErr, createResult) => {
                if (createErr) return callback(createErr);
                callback(null, Number(createResult.insertId), true);
            }
        );
    });
}

function resolveOrCreateClase({
    grupoId,
    nombreGrupo,
    nombreMateria,
    profesorId
}, callback) {
    resolveOrCreateGrupoId({ grupoId, nombreGrupo }, (groupErr, resolvedGrupoId, grupoCreado) => {
        if (groupErr) return callback(groupErr);

        resolveOrCreateMateriaId(nombreMateria, (subjectErr, materiaId, materiaCreada) => {
            if (subjectErr) return callback(subjectErr);

            const profesorIdNormalizado = profesorId || null;
            const existingClassSql = `
                SELECT id
                FROM materias_grupos
                WHERE grupo_id = ?
                  AND materia_id = ?
                  AND (profesor_id <=> ?)
                LIMIT 1
            `;

            db.query(
                existingClassSql,
                [resolvedGrupoId, materiaId, profesorIdNormalizado],
                (existingErr, classRows) => {
                    if (existingErr) return callback(existingErr);

                    if (classRows.length > 0) {
                        return callback(null, {
                            id: Number(classRows[0].id),
                            grupoId: resolvedGrupoId,
                            grupoCreado,
                            materiaCreada,
                            claseExistente: true
                        });
                    }

                    const insertClassSql = `
                        INSERT INTO materias_grupos (grupo_id, materia_id, profesor_id)
                        VALUES (?, ?, ?)
                    `;

                    db.query(
                        insertClassSql,
                        [resolvedGrupoId, materiaId, profesorIdNormalizado],
                        (insertErr, insertResult) => {
                            if (insertErr) return callback(insertErr);

                            callback(null, {
                                id: Number(insertResult.insertId),
                                grupoId: resolvedGrupoId,
                                grupoCreado,
                                materiaCreada,
                                claseExistente: false
                            });
                        }
                    );
                }
            );
        });
    });
}

function groupAttendanceRows(rows) {
    const map = new Map();

    for (const row of rows) {
        const recordId = Number(row.registro_id || row.id || 0);
        if (!map.has(recordId)) {
            map.set(recordId, {
                id: recordId,
                grupo_id: Number(row.clase_id || 0),
                grupo_nombre: row.grupo_nombre || 'Grupo',
                materia: row.materia || 'Materia',
                fecha: formatDateValue(row.fecha),
                detalles: []
            });
        }

        if (row.alumno_id !== null && row.alumno_id !== undefined) {
            map.get(recordId).detalles.push({
                alumno_id: Number(row.alumno_id || 0),
                nombre: row.alumno_nombre || 'Sin nombre',
                correo: row.alumno_correo || 'Sin correo',
                estado: normalizeAttendanceStatus(row.estado),
                nota: row.nota || ''
            });
        }
    }

    return Array.from(map.values()).sort((left, right) => {
        return String(right.fecha).localeCompare(String(left.fecha));
    });
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

function queryAsync(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.query(sql, params, (err, results) => {
            if (err) {
                reject(err);
            } else {
                resolve(results);
            }
        });
    });
}

function normalizeRole(value) {
    const role = String(value || '').trim().toLowerCase();
    return role === 'maestro' ? 'profesor' : role;
}

async function getLinkedStudentIdForTutor(tutorId) {
    const rows = await queryAsync(
        'SELECT alumno_id FROM tutores_alumnos WHERE tutor_id = ? LIMIT 1',
        [tutorId]
    );

    if (!rows.length) {
        return null;
    }

    return Number(rows[0].alumno_id || 0) || null;
}

async function getTeacherIdsForStudent(alumnoId, materia = '') {
    const hasMateria = Boolean(String(materia || '').trim());
    const sql = `
        SELECT DISTINCT mg.profesor_id
        FROM alumnos_grupos ag
        JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id
        JOIN materias m ON mg.materia_id = m.id
        WHERE ag.alumno_id = ?
          AND mg.profesor_id IS NOT NULL
          ${hasMateria ? "AND CONVERT(m.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci = CAST(? AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_unicode_ci" : ''}
    `;

    const rows = await queryAsync(
        sql,
        hasMateria ? [alumnoId, materia.trim()] : [alumnoId]
    );

    return rows
        .map((row) => Number(row.profesor_id || 0))
        .filter((value) => value > 0);
}

async function resolveStudentById(alumnoId) {
    const studentUsers = await queryAsync(
        `
            SELECT id, nombre, email
            FROM usuarios
            WHERE id = ? AND rol = 'alumno'
            LIMIT 1
        `,
        [alumnoId]
    );

    if (studentUsers.length) {
        return {
            id: Number(studentUsers[0].id || 0),
            nombre: studentUsers[0].nombre || 'Alumno',
            correo: studentUsers[0].email || `alumno${alumnoId}@legacy.local`
        };
    }

    const legacyStudents = await queryAsync(
        `
            SELECT id, nombre
            FROM alumnos
            WHERE id = ?
            LIMIT 1
        `,
        [alumnoId]
    );

    if (legacyStudents.length) {
        return {
            id: Number(legacyStudents[0].id || 0),
            nombre: legacyStudents[0].nombre || 'Alumno',
            correo: `alumno${alumnoId}@legacy.local`
        };
    }

    return null;
}

async function obtenerClaseMeta(claseId) {
    const sql = `
        SELECT
            mg.id,
            mg.grupo_id,
            mg.materia_id,
            g.nombre AS grupo_nombre,
            m.nombre AS materia_nombre
        FROM materias_grupos mg
        JOIN grupos g ON mg.grupo_id = g.id
        JOIN materias m ON mg.materia_id = m.id
        WHERE mg.id = ?
        LIMIT 1
    `;

    const rows = await queryAsync(sql, [claseId]);
    return rows[0] || null;
}

async function obtenerAlumnosClase(claseId) {
    const sql = `
        SELECT DISTINCT
            ag.alumno_id,
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

    const rows = await queryAsync(sql, [claseId]);
    return rows.map((row) => ({
        alumno_id: Number(row.alumno_id || row.id || 0),
        id: Number(row.id || row.alumno_id || 0),
        nombre: row.nombre || 'Sin nombre',
        correo: row.correo || 'Sin correo'
    }));
}

function parseBooleanFlag(value, fallback = false) {
    if (value === null || value === undefined) {
        return fallback;
    }

    if (typeof value === 'boolean') {
        return value;
    }

    const normalized = String(value).trim().toLowerCase();
    return ['1', 'true', 'si', 'sí', 'yes'].includes(normalized);
}

function buildActivityStatus({ hasCapture, entregado, calificacion }) {
    if (!hasCapture) return 'Sin revisar';
    if (!entregado) return 'No entregado';
    if (calificacion === null) return 'Entregado';
    return 'Calificado';
}

function computeFinalSummary({
    alumno,
    actividades,
    capturasPorActividad,
    finalManual
}) {
    const totalActividades = actividades.length;
    let entregadas = 0;
    let noEntregadas = 0;
    let sinRegistrar = 0;
    let sumaCalificaciones = 0;
    let calificacionesCapturadas = 0;
    let puntosObtenidos = 0;
    let puntosPosibles = 0;
    let ultimoComentario = '';
    let ultimaFechaComentario = '';

    const detalleActividades = actividades.map((actividad) => {
        const captura = capturasPorActividad[actividad.id] || null;
        const hasCapture = captura !== null;
        const entregado = captura ? parseBooleanFlag(captura.entregado) : false;
        const calificacion = captura ? parseNullableGrade(captura.calificacion) : null;
        const comentario = captura ? String(captura.comentario || '') : '';
        const fechaActualizacion = captura
            ? String(captura.fecha_actualizacion || captura.fecha_registro || '')
            : '';

        if (!hasCapture) {
            sinRegistrar++;
        } else if (entregado) {
            entregadas++;
        } else {
            noEntregadas++;
        }

        if (entregado && calificacion !== null) {
            sumaCalificaciones += calificacion;
            calificacionesCapturadas++;
        }

        if (actividad.cuenta_para_final) {
            const valor = actividad.valor > 0 ? actividad.valor : 1;
            puntosPosibles += valor;

            if (entregado) {
                puntosObtenidos += ((calificacion ?? 0) / 10) * valor;
            }
        }

        if (comentario && fechaActualizacion >= ultimaFechaComentario) {
            ultimoComentario = comentario;
            ultimaFechaComentario = fechaActualizacion;
        }

        return {
            actividad_id: actividad.id,
            titulo: actividad.titulo,
            descripcion: actividad.descripcion || '',
            valor: actividad.valor,
            fecha_entrega: actividad.fecha_entrega || '',
            cuenta_para_final: actividad.cuenta_para_final,
            entregado: entregado,
            revisado: hasCapture,
            calificacion: calificacion,
            comentario: comentario,
            estado: buildActivityStatus({
                hasCapture,
                entregado,
                calificacion
            })
        };
    });

    const promedioActividades = calificacionesCapturadas > 0
        ? roundGrade(sumaCalificaciones / calificacionesCapturadas)
        : null;
    const calificacionSugerida = puntosPosibles > 0
        ? roundGrade((puntosObtenidos / puntosPosibles) * 10)
        : null;

    return {
        id: alumno.id,
        alumno_id: alumno.alumno_id,
        nombre: alumno.nombre,
        correo: alumno.correo,
        calificacion_final: finalManual,
        calificacion_sugerida: calificacionSugerida,
        promedio_actividades: promedioActividades,
        total_actividades: totalActividades,
        entregadas: entregadas,
        no_entregadas: noEntregadas,
        sin_registrar: sinRegistrar,
        ultimo_comentario: ultimoComentario,
        actividades: detalleActividades
    };
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

app.get('/clases/:clase_id/actividades', async (req, res) => {
    const claseId = Number.parseInt(req.params.clase_id, 10);

    if (Number.isNaN(claseId)) {
        return res.status(400).json({ error: 'Clase invalida' });
    }

    try {
        const sql = `
            SELECT
                ac.id,
                ac.clase_id,
                ac.titulo,
                ac.descripcion,
                ac.valor,
                ac.fecha_entrega,
                ac.cuenta_para_final,
                ac.fecha_registro,
                COUNT(aa.id) AS capturas,
                SUM(CASE WHEN aa.entregado = 1 THEN 1 ELSE 0 END) AS entregados,
                SUM(CASE WHEN aa.id IS NOT NULL AND aa.entregado = 0 THEN 1 ELSE 0 END) AS no_entregados,
                ROUND(AVG(CASE WHEN aa.entregado = 1 AND aa.calificacion IS NOT NULL THEN aa.calificacion END), 2) AS promedio
            FROM actividades_clase ac
            LEFT JOIN actividades_alumnos aa ON aa.actividad_id = ac.id
            WHERE ac.clase_id = ?
            GROUP BY
                ac.id,
                ac.clase_id,
                ac.titulo,
                ac.descripcion,
                ac.valor,
                ac.fecha_entrega,
                ac.cuenta_para_final,
                ac.fecha_registro
            ORDER BY COALESCE(ac.fecha_entrega, DATE(ac.fecha_registro)) DESC, ac.id DESC
        `;

        const rows = await queryAsync(sql, [claseId]);
        res.json(rows.map((row) => ({
            id: Number(row.id || 0),
            clase_id: Number(row.clase_id || claseId),
            titulo: row.titulo || 'Actividad',
            descripcion: row.descripcion || '',
            valor: parseNullableGrade(row.valor) ?? 0,
            fecha_entrega: row.fecha_entrega ? String(row.fecha_entrega) : '',
            cuenta_para_final: parseBooleanFlag(row.cuenta_para_final, true),
            capturas: Number(row.capturas || 0),
            entregados: Number(row.entregados || 0),
            no_entregados: Number(row.no_entregados || 0),
            promedio: parseNullableGrade(row.promedio)
        })));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/clases/:clase_id/actividades', async (req, res) => {
    const claseId = Number.parseInt(req.params.clase_id, 10);
    const titulo = String(req.body.titulo || '').trim();
    const descripcion = String(req.body.descripcion || '').trim();
    const valor = parseNullableGrade(req.body.valor);
    const fechaEntrega = String(req.body.fecha_entrega || '').trim();
    const cuentaParaFinal = parseBooleanFlag(req.body.cuenta_para_final, true);

    if (Number.isNaN(claseId)) {
        return res.status(400).json({ error: 'Clase invalida' });
    }

    if (!titulo) {
        return res.status(400).json({ error: 'El titulo es obligatorio' });
    }

    if (valor === null || valor <= 0) {
        return res.status(400).json({ error: 'El valor de la actividad debe ser mayor a 0' });
    }

    try {
        const clase = await obtenerClaseMeta(claseId);
        if (!clase) {
            return res.status(404).json({ error: 'Clase no encontrada' });
        }

        const insertSql = `
            INSERT INTO actividades_clase (
                clase_id,
                titulo,
                descripcion,
                valor,
                fecha_entrega,
                cuenta_para_final,
                fecha_registro,
                fecha_actualizacion
            )
            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
        `;

        const result = await queryAsync(insertSql, [
            claseId,
            titulo,
            descripcion || null,
            valor,
            fechaEntrega || null,
            cuentaParaFinal ? 1 : 0
        ]);

        res.status(201).json({
            id: result.insertId,
            message: 'Actividad creada'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/actividades/:actividad_id/detalle', async (req, res) => {
    const actividadId = Number.parseInt(req.params.actividad_id, 10);

    if (Number.isNaN(actividadId)) {
        return res.status(400).json({ error: 'Actividad invalida' });
    }

    try {
        const actividadSql = `
            SELECT
                ac.id,
                ac.clase_id,
                ac.titulo,
                ac.descripcion,
                ac.valor,
                ac.fecha_entrega,
                ac.cuenta_para_final,
                g.nombre AS grupo_nombre,
                m.nombre AS materia
            FROM actividades_clase ac
            JOIN materias_grupos mg ON mg.id = ac.clase_id
            JOIN grupos g ON g.id = mg.grupo_id
            JOIN materias m ON m.id = mg.materia_id
            WHERE ac.id = ?
            LIMIT 1
        `;

        const actividadRows = await queryAsync(actividadSql, [actividadId]);
        if (!actividadRows.length) {
            return res.status(404).json({ error: 'Actividad no encontrada' });
        }

        const actividad = actividadRows[0];
        const alumnos = await obtenerAlumnosClase(actividad.clase_id);
        const capturasRows = await queryAsync(
            `
                SELECT
                    alumno_id,
                    entregado,
                    calificacion,
                    comentario,
                    fecha_registro,
                    fecha_actualizacion
                FROM actividades_alumnos
                WHERE actividad_id = ?
            `,
            [actividadId]
        );

        const capturasMap = {};
        for (const captura of capturasRows) {
            capturasMap[captura.alumno_id] = captura;
        }

        res.json({
            id: Number(actividad.id || 0),
            clase_id: Number(actividad.clase_id || 0),
            titulo: actividad.titulo || 'Actividad',
            descripcion: actividad.descripcion || '',
            valor: parseNullableGrade(actividad.valor) ?? 0,
            fecha_entrega: actividad.fecha_entrega ? String(actividad.fecha_entrega) : '',
            cuenta_para_final: parseBooleanFlag(actividad.cuenta_para_final, true),
            grupo_nombre: actividad.grupo_nombre || '',
            materia: actividad.materia || '',
            alumnos: alumnos.map((alumno) => {
                const captura = capturasMap[alumno.alumno_id] || null;
                const entregado = captura ? parseBooleanFlag(captura.entregado) : false;
                const calificacion = captura ? parseNullableGrade(captura.calificacion) : null;
                const comentario = captura ? String(captura.comentario || '') : '';
                const revisado = captura !== null;

                return {
                    alumno_id: alumno.alumno_id,
                    id: alumno.id,
                    nombre: alumno.nombre,
                    correo: alumno.correo,
                    entregado: entregado,
                    revisado: revisado,
                    calificacion: calificacion,
                    comentario: comentario,
                    estado: buildActivityStatus({
                        hasCapture: revisado,
                        entregado,
                        calificacion
                    })
                };
            })
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/actividades/:actividad_id/capturas', async (req, res) => {
    const actividadId = Number.parseInt(req.params.actividad_id, 10);
    const capturas = Array.isArray(req.body.capturas) ? req.body.capturas : [];

    if (Number.isNaN(actividadId)) {
        return res.status(400).json({ error: 'Actividad invalida' });
    }

    if (!capturas.length) {
        return res.status(400).json({ error: 'No hay capturas para guardar' });
    }

    try {
        const actividadRows = await queryAsync(
            'SELECT id FROM actividades_clase WHERE id = ? LIMIT 1',
            [actividadId]
        );

        if (!actividadRows.length) {
            return res.status(404).json({ error: 'Actividad no encontrada' });
        }

        const values = [];
        for (const item of capturas) {
            const alumnoId = Number.parseInt(item.alumno_id, 10);
            const entregado = parseBooleanFlag(item.entregado);
            const calificacion = parseNullableGrade(item.calificacion);
            const comentario = String(item.comentario || '').trim();

            if (Number.isNaN(alumnoId) || alumnoId <= 0) {
                return res.status(400).json({ error: 'Alumno invalido en capturas' });
            }

            if (calificacion !== null && (calificacion < 0 || calificacion > 10)) {
                return res.status(400).json({ error: 'La calificacion debe estar entre 0 y 10' });
            }

            values.push([
                actividadId,
                alumnoId,
                entregado ? 1 : 0,
                entregado ? calificacion : null,
                comentario || null
            ]);
        }

        await queryAsync(
            `
                INSERT INTO actividades_alumnos (
                    actividad_id,
                    alumno_id,
                    entregado,
                    calificacion,
                    comentario
                )
                VALUES ?
                ON DUPLICATE KEY UPDATE
                    entregado = VALUES(entregado),
                    calificacion = VALUES(calificacion),
                    comentario = VALUES(comentario),
                    fecha_actualizacion = NOW()
            `,
            [values]
        );

        res.json({ message: 'Capturas guardadas' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/clases/:clase_id/finales_resumen', async (req, res) => {
    const claseId = Number.parseInt(req.params.clase_id, 10);

    if (Number.isNaN(claseId)) {
        return res.status(400).json({ error: 'Clase invalida' });
    }

    try {
        const clase = await obtenerClaseMeta(claseId);
        if (!clase) {
            return res.status(404).json({ error: 'Clase no encontrada' });
        }

        const alumnos = await obtenerAlumnosClase(claseId);
        const actividades = await queryAsync(
            `
                SELECT
                    id,
                    clase_id,
                    titulo,
                    descripcion,
                    valor,
                    fecha_entrega,
                    cuenta_para_final
                FROM actividades_clase
                WHERE clase_id = ?
                ORDER BY COALESCE(fecha_entrega, DATE(fecha_registro)) DESC, id DESC
            `,
            [claseId]
        );
        const capturas = await queryAsync(
            `
                SELECT
                    aa.actividad_id,
                    aa.alumno_id,
                    aa.entregado,
                    aa.calificacion,
                    aa.comentario,
                    aa.fecha_registro,
                    aa.fecha_actualizacion
                FROM actividades_alumnos aa
                JOIN actividades_clase ac ON ac.id = aa.actividad_id
                WHERE ac.clase_id = ?
            `,
            [claseId]
        );
        const finalesRows = await queryAsync(
            `
                SELECT alumno_id, calificacion
                FROM calificaciones_finales
                WHERE materia_id = ?
            `,
            [clase.materia_id]
        );

        const actividadesNormalizadas = actividades.map((actividad) => ({
            id: Number(actividad.id || 0),
            titulo: actividad.titulo || 'Actividad',
            descripcion: actividad.descripcion || '',
            valor: parseNullableGrade(actividad.valor) ?? 0,
            fecha_entrega: actividad.fecha_entrega ? String(actividad.fecha_entrega) : '',
            cuenta_para_final: parseBooleanFlag(actividad.cuenta_para_final, true)
        }));

        const finalesMap = {};
        for (const row of finalesRows) {
            finalesMap[row.alumno_id] = parseNullableGrade(row.calificacion);
        }

        const capturasPorAlumno = {};
        for (const captura of capturas) {
            if (!capturasPorAlumno[captura.alumno_id]) {
                capturasPorAlumno[captura.alumno_id] = {};
            }
            capturasPorAlumno[captura.alumno_id][captura.actividad_id] = captura;
        }

        const resumen = alumnos.map((alumno) => {
            const finalManual = finalesMap[alumno.alumno_id] ?? null;
            return computeFinalSummary({
                alumno,
                actividades: actividadesNormalizadas,
                capturasPorActividad: capturasPorAlumno[alumno.alumno_id] || {},
                finalManual
            });
        });

        res.json({
            clase_id: claseId,
            grupo_nombre: clase.grupo_nombre,
            materia: clase.materia_nombre,
            alumnos: resumen
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/clases/:clase_id/alumnos/:alumno_id/final_resumen', async (req, res) => {
    const claseId = Number.parseInt(req.params.clase_id, 10);
    const alumnoId = Number.parseInt(req.params.alumno_id, 10);

    if (Number.isNaN(claseId) || Number.isNaN(alumnoId)) {
        return res.status(400).json({ error: 'Parametros invalidos' });
    }

    try {
        const clase = await obtenerClaseMeta(claseId);
        if (!clase) {
            return res.status(404).json({ error: 'Clase no encontrada' });
        }

        const alumnos = await obtenerAlumnosClase(claseId);
        const alumno = alumnos.find((item) => item.alumno_id === alumnoId);
        if (!alumno) {
            return res.status(404).json({ error: 'Alumno no encontrado en la clase' });
        }

        const actividades = await queryAsync(
            `
                SELECT
                    id,
                    titulo,
                    descripcion,
                    valor,
                    fecha_entrega,
                    cuenta_para_final
                FROM actividades_clase
                WHERE clase_id = ?
                ORDER BY COALESCE(fecha_entrega, DATE(fecha_registro)) DESC, id DESC
            `,
            [claseId]
        );
        const capturas = await queryAsync(
            `
                SELECT
                    actividad_id,
                    alumno_id,
                    entregado,
                    calificacion,
                    comentario,
                    fecha_registro,
                    fecha_actualizacion
                FROM actividades_alumnos
                WHERE alumno_id = ?
                  AND actividad_id IN (
                    SELECT id
                    FROM actividades_clase
                    WHERE clase_id = ?
                  )
            `,
            [alumnoId, claseId]
        );
        const finalRows = await queryAsync(
            `
                SELECT calificacion
                FROM calificaciones_finales
                WHERE alumno_id = ?
                  AND materia_id = ?
                LIMIT 1
            `,
            [alumnoId, clase.materia_id]
        );

        const actividadesNormalizadas = actividades.map((actividad) => ({
            id: Number(actividad.id || 0),
            titulo: actividad.titulo || 'Actividad',
            descripcion: actividad.descripcion || '',
            valor: parseNullableGrade(actividad.valor) ?? 0,
            fecha_entrega: actividad.fecha_entrega ? String(actividad.fecha_entrega) : '',
            cuenta_para_final: parseBooleanFlag(actividad.cuenta_para_final, true)
        }));

        const capturasPorActividad = {};
        for (const captura of capturas) {
            capturasPorActividad[captura.actividad_id] = captura;
        }

        const summary = computeFinalSummary({
            alumno,
            actividades: actividadesNormalizadas,
            capturasPorActividad,
            finalManual: finalRows.length ? parseNullableGrade(finalRows[0].calificacion) : null
        });

        res.json({
            clase_id: claseId,
            grupo_nombre: clase.grupo_nombre,
            materia: clase.materia_nombre,
            alumno: summary
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
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

app.post('/register_tutor', async (req, res) => {
    const nombre = String(req.body.nombre || '').trim();
    const email = String(req.body.email || req.body.correo || '').trim();
    const password = String(req.body.password || req.body.contrasena || '').trim();
    const matriculaHijo = Number.parseInt(
        req.body.matricula_hijo ?? req.body.alumno_id_vinculado,
        10
    );

    if (!nombre || !email || !password) {
        return res.status(400).json({ error: 'Faltan datos de registro para tutor' });
    }

    if (Number.isNaN(matriculaHijo) || matriculaHijo <= 0) {
        return res.status(400).json({ error: 'La matricula del hijo es obligatoria para registrar un tutor.' });
    }

    try {
        const linkedStudent = await resolveStudentById(matriculaHijo);

        if (!linkedStudent) {
            return res.status(400).json({ error: 'Seguridad: La matricula del hijo no existe.' });
        }

        const result = await queryAsync(
            'INSERT INTO usuarios (nombre, email, password, rol) VALUES (?, ?, ?, ?)',
            [nombre, email, password, 'tutor']
        );

        await queryAsync(
            `
                INSERT INTO tutores_alumnos (tutor_id, alumno_id)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE alumno_id = VALUES(alumno_id)
            `,
            [result.insertId, matriculaHijo]
        );

        crearNotificacion(
            result.insertId,
            'Bienvenido Tutor',
            `Tu cuenta ha sido vinculada correctamente con ${linkedStudent.nombre || 'tu alumno'}.`
        );

        res.status(201).json({
            message: 'Tutor registrado exitosamente',
            id: result.insertId
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/tutores/:tutor_id/alumno', async (req, res) => {
    const tutorId = Number.parseInt(req.params.tutor_id, 10);

    if (Number.isNaN(tutorId) || tutorId <= 0) {
        return res.status(400).json({ error: 'Tutor invalido' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    ta.alumno_id AS id,
                    COALESCE(u.nombre, a.nombre, 'Alumno vinculado') AS nombre,
                    COALESCE(u.email, CONCAT('alumno', ta.alumno_id, '@legacy.local')) AS correo
                FROM tutores_alumnos ta
                LEFT JOIN usuarios u ON u.id = ta.alumno_id AND u.rol = 'alumno'
                LEFT JOIN alumnos a ON a.id = ta.alumno_id
                WHERE ta.tutor_id = ?
                LIMIT 1
            `,
            [tutorId]
        );

        if (!rows.length) {
            return res.status(404).json({ error: 'Este tutor aun no tiene un alumno vinculado.' });
        }

        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/tutores/:tutor_id/reportes', async (req, res) => {
    const tutorId = Number.parseInt(req.params.tutor_id, 10);

    if (Number.isNaN(tutorId) || tutorId <= 0) {
        return res.status(400).json({ error: 'Tutor invalido' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    rt.id,
                    rt.categoria,
                    rt.materia,
                    rt.titulo,
                    rt.mensaje,
                    rt.estado,
                    rt.fecha_registro,
                    rta.nombre_original AS adjunto_nombre,
                    rta.mime_type AS adjunto_mime_type,
                    rta.tamano_bytes AS adjunto_tamano,
                    rta.ruta_relativa AS adjunto_ruta
                FROM reportes_tutor rt
                LEFT JOIN reportes_tutor_adjuntos rta ON rta.reporte_id = rt.id
                WHERE rt.tutor_id = ?
                ORDER BY rt.fecha_registro DESC, rt.id DESC
            `,
            [tutorId]
        );

        res.json(rows.map((row) => ({
            id: Number(row.id || 0),
            categoria: row.categoria || 'Reporte',
            materia: row.materia || '',
            titulo: row.titulo || 'Reporte del tutor',
            mensaje: row.mensaje || '',
            estado: row.estado || 'Enviado',
            fecha: row.fecha_registro instanceof Date
                ? row.fecha_registro.toISOString()
                : String(row.fecha_registro || ''),
            adjunto_nombre: row.adjunto_nombre || '',
            adjunto_mime_type: row.adjunto_mime_type || '',
            adjunto_tamano: Number(row.adjunto_tamano || 0),
            adjunto_url: row.adjunto_ruta
                ? buildPublicUploadUrl(req, row.adjunto_ruta)
                : ''
        })));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/tutores/:tutor_id/reportes', async (req, res) => {
    const tutorId = Number.parseInt(req.params.tutor_id, 10);
    const alumnoIdBody = Number.parseInt(req.body.alumno_id, 10);
    const categoria = String(req.body.categoria || 'Reporte general').trim();
    const materia = String(req.body.materia || '').trim();
    const titulo = String(req.body.titulo || 'Mensaje del tutor').trim();
    const mensaje = String(req.body.mensaje || '').trim();
    let attachment = null;

    if (Number.isNaN(tutorId) || tutorId <= 0) {
        return res.status(400).json({ error: 'Tutor invalido' });
    }

    if (!titulo || !mensaje) {
        return res.status(400).json({ error: 'Faltan datos del reporte del tutor' });
    }

    try {
        attachment = parseTutorReportAttachment(req.body.attachment);
    } catch (attachmentError) {
        return res.status(400).json({ error: attachmentError.message });
    }

    try {
        const linkedStudentId = !Number.isNaN(alumnoIdBody) && alumnoIdBody > 0
            ? alumnoIdBody
            : await getLinkedStudentIdForTutor(tutorId);

        if (!linkedStudentId) {
            return res.status(400).json({ error: 'No se encontro un alumno vinculado para este tutor.' });
        }

        const [tutorRows, studentRows] = await Promise.all([
            queryAsync('SELECT nombre FROM usuarios WHERE id = ? LIMIT 1', [tutorId]),
            queryAsync(
                `
                    SELECT COALESCE(u.nombre, a.nombre, 'Alumno') AS nombre
                    FROM (SELECT ? AS alumno_id) ref
                    LEFT JOIN usuarios u ON u.id = ref.alumno_id AND u.rol = 'alumno'
                    LEFT JOIN alumnos a ON a.id = ref.alumno_id
                    LIMIT 1
                `,
                [linkedStudentId]
            )
        ]);

        const insertResult = await queryAsync(
            `
                INSERT INTO reportes_tutor (
                    tutor_id,
                    alumno_id,
                    categoria,
                    materia,
                    titulo,
                    mensaje,
                    estado
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `,
            [
                tutorId,
                linkedStudentId,
                categoria,
                materia || null,
                titulo,
                mensaje,
                categoria === 'Justificacion de falta' ? 'En revision' : 'Enviado'
            ]
        );
        let attachmentMeta = null;

        try {
            if (attachment) {
                attachmentMeta = await saveTutorReportAttachment(
                    insertResult.insertId,
                    attachment
                );
            }
        } catch (attachmentError) {
            await queryAsync('DELETE FROM reportes_tutor WHERE id = ?', [
                insertResult.insertId
            ]).catch(() => {});
            throw attachmentError;
        }

        const tutorName = tutorRows[0]?.nombre || 'Tutor';
        const studentName = studentRows[0]?.nombre || 'Alumno';
        const teacherIds = await getTeacherIdsForStudent(linkedStudentId, materia);
        const notificationTitle = categoria === 'Justificacion de falta'
            ? 'Nueva justificacion de tutor'
            : 'Nuevo reporte de tutor';
        const subjectLabel = materia ? ` en ${materia}` : '';
        const notificationMessage =
            `${tutorName} envio ${categoria.toLowerCase()} sobre ${studentName}${subjectLabel}: ${titulo}.`;

        await Promise.all(
            teacherIds.map((teacherId) =>
                queryAsync(
                    'INSERT INTO notificaciones (usuario_id, titulo, mensaje, fecha) VALUES (?, ?, ?, NOW())',
                    [teacherId, notificationTitle, notificationMessage]
                )
            )
        );

        crearNotificacion(
            tutorId,
            'Reporte enviado',
            `Tu reporte para ${studentName}${subjectLabel} fue enviado correctamente.`
        );

        res.status(201).json({
            id: insertResult.insertId,
            message: 'Reporte del tutor enviado correctamente',
            notified_teachers: teacherIds.length,
            adjunto: attachmentMeta
                ? {
                    nombre: attachmentMeta.nombre,
                    mime_type: attachmentMeta.mimeType,
                    tamano_bytes: attachmentMeta.tamanoBytes,
                    url: buildPublicUploadUrl(req, attachmentMeta.rutaRelativa)
                }
                : null
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/profesores/:profesor_id/reportes_tutor', async (req, res) => {
    const profesorId = Number.parseInt(req.params.profesor_id, 10);

    if (Number.isNaN(profesorId) || profesorId <= 0) {
        return res.status(400).json({ error: 'Profesor invalido' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    rt.id,
                    rt.tutor_id,
                    rt.alumno_id,
                    rt.categoria,
                    rt.materia,
                    rt.titulo,
                    rt.mensaje,
                    rt.estado,
                    rt.fecha_registro,
                    COALESCE(tu.nombre, 'Tutor') AS tutor_nombre,
                    COALESCE(au.nombre, al.nombre, 'Alumno') AS alumno_nombre,
                    rta.nombre_original AS adjunto_nombre,
                    rta.mime_type AS adjunto_mime_type,
                    rta.tamano_bytes AS adjunto_tamano,
                    rta.ruta_relativa AS adjunto_ruta
                FROM reportes_tutor rt
                LEFT JOIN usuarios tu ON tu.id = rt.tutor_id
                LEFT JOIN usuarios au ON au.id = rt.alumno_id AND au.rol = 'alumno'
                LEFT JOIN alumnos al ON al.id = rt.alumno_id
                LEFT JOIN reportes_tutor_adjuntos rta ON rta.reporte_id = rt.id
                WHERE EXISTS (
                    SELECT 1
                    FROM alumnos_grupos ag
                    JOIN materias_grupos mg ON ag.grupo_id = mg.grupo_id
                    JOIN materias m ON mg.materia_id = m.id
                    WHERE ag.alumno_id = rt.alumno_id
                      AND mg.profesor_id = ?
                      AND (
                        rt.materia IS NULL
                        OR TRIM(rt.materia) = ''
                        OR CONVERT(m.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci =
                           CONVERT(rt.materia USING utf8mb4) COLLATE utf8mb4_unicode_ci
                      )
                )
                ORDER BY rt.fecha_registro DESC, rt.id DESC
            `,
            [profesorId]
        );

        res.json(rows.map((row) => ({
            id: Number(row.id || 0),
            tutor_id: Number(row.tutor_id || 0),
            alumno_id: Number(row.alumno_id || 0),
            categoria: row.categoria || 'Reporte',
            materia: row.materia || '',
            titulo: row.titulo || 'Mensaje del tutor',
            mensaje: row.mensaje || '',
            estado: row.estado || 'En revision',
            fecha: formatDateValue(row.fecha_registro),
            tutor_nombre: row.tutor_nombre || 'Tutor',
            alumno_nombre: row.alumno_nombre || 'Alumno',
            adjunto_nombre: row.adjunto_nombre || '',
            adjunto_mime_type: row.adjunto_mime_type || '',
            adjunto_tamano: Number(row.adjunto_tamano || 0),
            adjunto_url: row.adjunto_ruta
                ? buildPublicUploadUrl(req, row.adjunto_ruta)
                : ''
        })));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/asistencias', async (req, res) => {
    const claseId = Number.parseInt(req.body.clase_id, 10);
    const fechaRaw = String(req.body.fecha || '').trim();
    const detalles = Array.isArray(req.body.detalles) ? req.body.detalles : [];
    const fecha = fechaRaw.slice(0, 10);

    if (Number.isNaN(claseId) || claseId <= 0) {
        return res.status(400).json({ error: 'Clase invalida' });
    }

    if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha)) {
        return res.status(400).json({ error: 'La fecha debe usar formato YYYY-MM-DD' });
    }

    if (!detalles.length) {
        return res.status(400).json({ error: 'Debes enviar al menos un detalle de asistencia' });
    }

    try {
        const claseMeta = await obtenerClaseMeta(claseId);
        if (!claseMeta) {
            return res.status(404).json({ error: 'La clase no existe' });
        }

        const normalizedDetails = detalles
            .map((item) => ({
                alumno_id: Number.parseInt(item.alumno_id, 10),
                estado: normalizeAttendanceStatus(item.estado),
                nota: String(item.nota || '').trim()
            }))
            .filter((item) => !Number.isNaN(item.alumno_id) && item.alumno_id > 0);

        if (!normalizedDetails.length) {
            return res.status(400).json({ error: 'No se encontraron alumnos validos para guardar asistencia' });
        }

        const result = await queryAsync(
            `
                INSERT INTO asistencias_registro (clase_id, fecha)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE
                    id = LAST_INSERT_ID(id),
                    fecha_actualizacion = NOW()
            `,
            [claseId, fecha]
        );

        const registroId = Number(result.insertId || 0);
        await queryAsync('DELETE FROM asistencias_detalle WHERE registro_id = ?', [registroId]);

        await queryAsync(
            `
                INSERT INTO asistencias_detalle (
                    registro_id,
                    alumno_id,
                    estado,
                    nota
                )
                VALUES ?
            `,
            [
                normalizedDetails.map((item) => [
                    registroId,
                    item.alumno_id,
                    item.estado,
                    item.nota || null
                ])
            ]
        );

        res.status(201).json({
            id: registroId,
            clase_id: claseId,
            grupo_nombre: claseMeta.grupo_nombre || 'Grupo',
            materia: claseMeta.materia_nombre || 'Materia',
            fecha
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/asistencias/clases/:clase_id', async (req, res) => {
    const claseId = Number.parseInt(req.params.clase_id, 10);

    if (Number.isNaN(claseId) || claseId <= 0) {
        return res.status(400).json({ error: 'Clase invalida' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    ar.id AS registro_id,
                    ar.clase_id,
                    g.nombre AS grupo_nombre,
                    m.nombre AS materia,
                    DATE_FORMAT(ar.fecha, '%Y-%m-%d') AS fecha,
                    ad.alumno_id,
                    COALESCE(u.nombre, a.nombre, 'Sin nombre') AS alumno_nombre,
                    COALESCE(u.email, CONCAT('alumno', ad.alumno_id, '@legacy.local')) AS alumno_correo,
                    ad.estado,
                    ad.nota
                FROM asistencias_registro ar
                JOIN materias_grupos mg ON mg.id = ar.clase_id
                JOIN grupos g ON g.id = mg.grupo_id
                JOIN materias m ON m.id = mg.materia_id
                LEFT JOIN asistencias_detalle ad ON ad.registro_id = ar.id
                LEFT JOIN usuarios u ON u.id = ad.alumno_id AND u.rol = 'alumno'
                LEFT JOIN alumnos a ON a.id = ad.alumno_id
                WHERE ar.clase_id = ?
                ORDER BY ar.fecha DESC, alumno_nombre ASC
            `,
            [claseId]
        );

        res.json(groupAttendanceRows(rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/asistencias/:registro_id', async (req, res) => {
    const registroId = Number.parseInt(req.params.registro_id, 10);

    if (Number.isNaN(registroId) || registroId <= 0) {
        return res.status(400).json({ error: 'Registro invalido' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    ar.id AS registro_id,
                    ar.clase_id,
                    g.nombre AS grupo_nombre,
                    m.nombre AS materia,
                    DATE_FORMAT(ar.fecha, '%Y-%m-%d') AS fecha,
                    ad.alumno_id,
                    COALESCE(u.nombre, a.nombre, 'Sin nombre') AS alumno_nombre,
                    COALESCE(u.email, CONCAT('alumno', ad.alumno_id, '@legacy.local')) AS alumno_correo,
                    ad.estado,
                    ad.nota
                FROM asistencias_registro ar
                JOIN materias_grupos mg ON mg.id = ar.clase_id
                JOIN grupos g ON g.id = mg.grupo_id
                JOIN materias m ON m.id = mg.materia_id
                LEFT JOIN asistencias_detalle ad ON ad.registro_id = ar.id
                LEFT JOIN usuarios u ON u.id = ad.alumno_id AND u.rol = 'alumno'
                LEFT JOIN alumnos a ON a.id = ad.alumno_id
                WHERE ar.id = ?
                ORDER BY alumno_nombre ASC
            `,
            [registroId]
        );

        const grouped = groupAttendanceRows(rows);
        if (!grouped.length) {
            return res.status(404).json({ error: 'No se encontro el registro de asistencia' });
        }

        res.json(grouped[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/asistencias/alumnos/:alumno_id', async (req, res) => {
    const alumnoId = Number.parseInt(req.params.alumno_id, 10);

    if (Number.isNaN(alumnoId) || alumnoId <= 0) {
        return res.status(400).json({ error: 'Alumno invalido' });
    }

    try {
        const rows = await queryAsync(
            `
                SELECT
                    ar.id AS registro_id,
                    ar.clase_id,
                    g.nombre AS grupo_nombre,
                    m.nombre AS materia,
                    DATE_FORMAT(ar.fecha, '%Y-%m-%d') AS fecha,
                    ad.alumno_id,
                    COALESCE(u.nombre, a.nombre, 'Sin nombre') AS alumno_nombre,
                    COALESCE(u.email, CONCAT('alumno', ad.alumno_id, '@legacy.local')) AS alumno_correo,
                    ad.estado,
                    ad.nota
                FROM asistencias_detalle ad
                JOIN asistencias_registro ar ON ar.id = ad.registro_id
                JOIN materias_grupos mg ON mg.id = ar.clase_id
                JOIN grupos g ON g.id = mg.grupo_id
                JOIN materias m ON m.id = mg.materia_id
                LEFT JOIN usuarios u ON u.id = ad.alumno_id AND u.rol = 'alumno'
                LEFT JOIN alumnos a ON a.id = ad.alumno_id
                WHERE ad.alumno_id = ?
                ORDER BY ar.fecha DESC, ar.id DESC
            `,
            [alumnoId]
        );

        res.json(rows.map((row) => ({
            registro_id: Number(row.registro_id || 0),
            clase_id: Number(row.clase_id || 0),
            grupo_nombre: row.grupo_nombre || 'Grupo',
            materia: row.materia || 'Materia',
            fecha: formatDateValue(row.fecha),
            alumno_id: Number(row.alumno_id || 0),
            alumno_nombre: row.alumno_nombre || 'Sin nombre',
            alumno_correo: row.alumno_correo || 'Sin correo',
            estado: normalizeAttendanceStatus(row.estado),
            nota: row.nota || ''
        })));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
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
    const { grupo_id, nombre_grupo, nombre_materia, profesor_id } = req.body;
    const nombreMateriaLimpio = normalizeTextValue(nombre_materia);
    const nombreGrupoLimpio = normalizeTextValue(nombre_grupo);
    const hasGrupoId = Number.isInteger(Number(grupo_id)) && Number(grupo_id) > 0;

    if (!nombreMateriaLimpio || (!hasGrupoId && !nombreGrupoLimpio)) {
        return res.status(400).json({ error: 'Faltan datos para crear la clase' });
    }

    resolveOrCreateClase(
        {
            grupoId: grupo_id,
            nombreGrupo: nombreGrupoLimpio,
            nombreMateria: nombreMateriaLimpio,
            profesorId: profesor_id
        },
        (err, result) => {
            if (err) {
                return res.status(500).json({ error: err.message || 'Error creando clase' });
            }

            res.json({
                message: result.claseExistente
                    ? 'La clase ya existia y se reutilizo'
                    : 'Clase creada exitosamente',
                id: result.id,
                grupo_id: result.grupoId,
                grupo_creado: result.grupoCreado,
                materia_creada: result.materiaCreada,
                clase_existente: result.claseExistente
            });
        }
    );
});

app.post('/grupos/crear', (req, res) => {
    const { nombre_grupo } = req.body;
    const nombreGrupoLimpio = normalizeTextValue(nombre_grupo);

    if (!nombreGrupoLimpio) {
        return res.status(400).json({ error: 'Falta nombre_grupo' });
    }

    resolveOrCreateGrupoId({ nombreGrupo: nombreGrupoLimpio }, (err, grupoId, grupoCreado) => {
        if (err) {
            return res.status(500).json({ error: err.message || 'Error creando grupo' });
        }

        res.json({
            id: grupoId,
            nombre: nombreGrupoLimpio,
            creado: grupoCreado
        });
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
app.get('/dashboard/:id', async (req, res) => {
    const studentId = Number.parseInt(req.params.id, 10);

    if (Number.isNaN(studentId) || studentId <= 0) {
        return res.status(400).json({ error: 'Alumno invalido' });
    }

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

    try {
        const alumno = await resolveStudentById(studentId);
        if (!alumno) {
            return res.status(404).json({ error: 'Alumno no encontrado' });
        }

        const [matResults, activitiesResults] = await Promise.all([
            queryAsync(sqlMaterias, [studentId]),
            queryAsync(sqlActividades, [studentId])
        ]);

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
                matricula: studentId.toString()
            },
            subjects: subjects
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
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
                    : averageActivities;

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
