import dotenv from "dotenv";
import path from "path"
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({path: __dirname + "/../../.env"});

export const PORT = process.env.PORT || 3000;
export const DATABASE_URL = process.env.DATABASE_URL || "postgres://admin:mysecretpassword@localhost:5432/mydatabase";
export const JWT_SECRET = process.env.JWT_SECRET || "super_secret_jwt_key_for_dev";

export const GMAIL_EMAIL = process.env.GMAIL_EMAIL;
export const GMAIL_PASSWORD = process.env.GMAIL_PASSWORD;
export const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
export const CHAT_ID = process.env.CHAT_ID;
// export const COULDFARE_SECRET_KEY = process.env.COULDFARE_SECRET_KEY;