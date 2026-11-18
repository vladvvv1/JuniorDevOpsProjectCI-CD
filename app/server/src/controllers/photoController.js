import { pool } from "../config/db.js";
import { v4 as uuidv4 } from "uuid";
import fs from "fs";
import path from "path";

const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

const assignCategoriesToPhotos = async (photoIds, categoryNames) => {
    // Шукаємо ID категорій
    const catQuery = "SELECT id FROM categories WHERE name = ANY($1)";
    const catRes = await pool.query(catQuery, [categoryNames]);
    
    if (catRes.rows.length === 0) throw new Error("No valid categories found");

    const insertPromises = [];
    for (const photoId of photoIds) {
        for (const cat of catRes.rows) {
            insertPromises.push(
                pool.query("INSERT INTO photo_categories (photo_id, category_id) VALUES ($1, $2)", [photoId, cat.id])
            );
        }
    }
    await Promise.all(insertPromises);
};

export const uploadPhoto = async (req, res) => {
    try {
        let { categories } = req.body;
        const files = req.files;
        const userId = req.user.id; // Беремо з authMiddleware

        if (!categories || !files || files.length === 0) {
            return res.status(400).json({ error: "No files or categories provided" });
        }
        if (typeof categories === "string") categories = JSON.parse(categories);

        const uploadedPhotos = [];
        
        for (const file of files) {
            if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) continue;

            const uniqueFileName = `${uuidv4()}-${file.originalname.replace(/\s/g, '_')}`;
            const uploadPath = path.join(process.cwd(), "uploads", "images", uniqueFileName);
            
            // Зберігаємо файл локально (замість supabase.storage)
            fs.writeFileSync(uploadPath, file.buffer);
            
            // Публічний URL (потрібно роздати папку uploads через express.static в index.js)
            const publicUrl = `/uploads/images/${uniqueFileName}`;

            // Запис в БД
            const insertPhoto = await pool.query(
                "INSERT INTO photos (url, user_id) VALUES ($1, $2) RETURNING id",
                [publicUrl, userId]
            );
            
            uploadedPhotos.push({
                photoId: insertPhoto.rows[0].id,
                url: publicUrl
            });
        }

        const photoIds = uploadedPhotos.map(p => p.photoId);
        await assignCategoriesToPhotos(photoIds, categories);

        res.json({ success: true, uploadedPhotos, message: "Pictures successfully uploaded." });
    } catch (err) {
        console.error("Upload error:", err.message);
        res.status(500).json({ error: "Internal server error" });
    }
};

export const getPhotos = async (req, res) => {
    try {
        let { category } = req.body;
        console.log(`\n🔍 Запит на фото. Категорія з фронтенду:`, category);
        
        if (!category) {
            return res.json([]); // Якщо фронт нічого не прислав
        }
        
        if (!Array.isArray(category)) category = [category];

        // Переводимо всі категорії в нижній регістр для пошуку
        const lowerCategories = category.map(c => c.toLowerCase());

        const query = `
            SELECT DISTINCT p.id, p.url, p.created_at
            FROM photos p
            JOIN photo_categories pc ON p.id = pc.photo_id
            JOIN categories c ON pc.category_id = c.id
            WHERE LOWER(c.name) = ANY($1)
        `;
        const result = await pool.query(query, [lowerCategories]);
        
        console.log(`✅ Знайдено фотографій у БД: ${result.rowCount}`);
        res.json(result.rows);
    } catch (err) {
        console.error("❌ Помилка БД при завантаженні фото:", err.message);
        res.status(500).json({ error: err.message });
    }
};

export const deletePhoto = async (req, res) => {
    try {
        const { url, category } = req.body;
        
        // Знаходимо фото та категорію
        const query = `
            SELECT p.id as photo_id, c.id as category_id 
            FROM photos p
            JOIN photo_categories pc ON p.id = pc.photo_id
            JOIN categories c ON pc.category_id = c.id
            WHERE p.url = $1 AND c.name = $2
        `;
        const result = await pool.query(query, [url, category]);
        
        if (result.rows.length === 0) return res.status(404).json({ error: "Photo not found in this category." });
        
        const { photo_id, category_id } = result.rows[0];

        // Видаляємо зв'язок
        await pool.query("DELETE FROM photo_categories WHERE photo_id = $1 AND category_id = $2", [photo_id, category_id]);

        // Перевіряємо, чи є фото в інших категоріях
        const checkRes = await pool.query("SELECT * FROM photo_categories WHERE photo_id = $1", [photo_id]);
        
        if (checkRes.rows.length === 0) {
            // Якщо ніде не використовується - видаляємо з БД і з диска
            await pool.query("DELETE FROM photos WHERE id = $1", [photo_id]);
            
            const fileName = url.split("/").pop();
            const filePath = path.join(process.cwd(), "uploads", "images", fileName);
            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
        }

        return res.json({ success: true, message: "Photo deleted successfully." });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};