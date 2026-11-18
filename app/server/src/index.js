import express from "express";
import { PORT } from "./config/config.js";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import cors from "cors";
import photoRoutes from "./routes/photoRoute.js";
import sendEmail from "./routes/contactRoute.js";
import authRoutes from "./routes/authRoute.js";
import path from "path";
import { pool } from "./config/db.js";

const app = express();
const __dirname = path.resolve();

app.use(express.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({ extended: true , limit: '50mb'}));
app.use(cookieParser());
app.use(cors({
    origin:["http://localhost:5500", "http://localhost:3000"],
    credentials: true,
}));

app.use(express.static(path.join(__dirname, "client", "src")));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "home", "index.html"));
});

app.get("/about", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "about", "about.html"));
});

app.get("/testimonials", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "testimonials", "testimonials.html"));
});

app.get("/portfolio/couples", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "couples", "couples.html"));
});

app.get("/portfolio/weddings", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "weddings", "weddings.html"));
});

app.get("/portfolio/individual", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "individual", "individual.html"));
});

app.get("/portfolio/family", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "family", "family.html"));
});

app.get("/portfolio/pregnancy", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "pregnancy", "pregnancy.html"));
});

app.get("/portfolio/foods", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "foods", "foods.html"));
});

app.get("/portfolio/christening", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "portfolio", "christening", "christening.html"));
});

app.get("/contact", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "contact", "contact.html"));
});

app.get("/login", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "adminka", "loginForm.html"));
});

app.get("/adminka", (req, res) => {
    res.sendFile(path.join(__dirname, "client", "src", "htmlforms", "adminka", "adminka.html"));
});

app.use("/photos", photoRoutes);
app.use("/auth", authRoutes);
app.use("/contacts", sendEmail);

setInterval(async () => {
    try {
        const res = await pool.query("SELECT * FROM categories");
        console.log("Keep-alive ping DB:", res.rowCount, "categories");
    } catch (e) {
        console.error("Keep-alive error:", e.message);
    }
}, 1800000);

app.listen(PORT, () => {
    console.log(`Server is running on host ${PORT}`);
})