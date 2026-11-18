import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { pool } from "../config/db.js";
import { JWT_SECRET } from "../config/config.js";

const router = express.Router();

router.post("/login", async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) return res.status(400).json({ error: "No email or password provided." });

        // Шукаємо користувача
        const userRes = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
        if (userRes.rows.length === 0) return res.status(401).json({ error: "Invalid credentials" });
        
        const user = userRes.rows[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) return res.status(401).json({ error: "Invalid credentials" });

        // Генеруємо токен
        const accessToken = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '1h' });

        res.cookie("access_token", accessToken, {
            httpOnly: true,
            sameSite: "Lax",
            secure: process.env.NODE_ENV === 'production',
            maxAge: 60 * 60 * 1000,
            path: "/"
        });

        return res.status(200).json({ success: true, user: { id: user.id, email: user.email } });
    } catch (error) {
        console.error("Login error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

router.post("/logout", (req, res) => {
    res.clearCookie("access_token");
    res.status(200).json({ success: true });
});

router.get("/check-token", (req, res) => {
    const token = req.cookies.access_token;
    if (!token) return res.status(401).json({ error: "No token provided." });

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) return res.status(401).json({ error: "Invalid or expired token" });
        res.status(200).json({ message: "Valid token", user: decoded });
    });
});

export default router;