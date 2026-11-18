import pkg from 'pg';
const { Pool } = pkg;
import { DATABASE_URL } from "./config.js";

export const pool = new Pool({
    connectionString: DATABASE_URL,
});

pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});