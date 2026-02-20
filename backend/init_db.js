const mysql = require('mysql2');

// Conexión a MySQL
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Saul2006'
});

// Crear la base de datos si no existe
connection.query(`CREATE DATABASE IF NOT EXISTS edutrack`, (err) => {
  if (err) throw err;
  console.log("Base de datos 'edutrack' creada o ya existe.");

  // Conectamos a la DB
  const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Saul2006',
    database: 'edutrack'
  });

  // Crear tablas
  const tables = `
    CREATE TABLE IF NOT EXISTS alumnos (
      id INT AUTO_INCREMENT PRIMARY KEY,
      nombre VARCHAR(100) NOT NULL,
      matricula VARCHAR(20) NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS maestros (
      id INT AUTO_INCREMENT PRIMARY KEY,
      nombre VARCHAR(100) NOT NULL,
      correo VARCHAR(100) NOT NULL UNIQUE,
      password VARCHAR(100) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS grupos (
      id INT AUTO_INCREMENT PRIMARY KEY,
      nombre VARCHAR(20) NOT NULL,
      materia VARCHAR(50) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS calificaciones (
      id INT AUTO_INCREMENT PRIMARY KEY,
      alumno_id INT NOT NULL,
      grupo_id INT NOT NULL,
      calificacion DECIMAL(4,2),
      FOREIGN KEY (alumno_id) REFERENCES alumnos(id),
      FOREIGN KEY (grupo_id) REFERENCES grupos(id)
    );
  `;

  db.query(tables, (err) => {
    if (err) throw err;
    console.log("Tablas creadas correctamente.");
    db.end();
  });
});
