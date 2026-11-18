import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../config/config.js";

export default (req, res, next) => {
    const token = req.cookies.access_token;
    if (!token) return res.status(401).json({ error: "Not authenticated" });

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).json({ error: "Access token expired, please log in again" });
        }
        req.user = decoded; // { id, email }
        next();
    });
};