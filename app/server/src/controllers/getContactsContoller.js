import { pool } from "../config/db.js";
import { transporter } from "../config/nodemailer.js";
import { GMAIL_EMAIL, TELEGRAM_BOT_TOKEN } from "../config/config.js";
import axios from "axios";
import TelegramBot from "node-telegram-bot-api"
import fs from "fs"
import path from "path"
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
console.log(__dirname);
let bot = null;

// Запускаємо бота ТІЛЬКИ якщо є токен
if (TELEGRAM_BOT_TOKEN && TELEGRAM_BOT_TOKEN !== "undefined") {
    bot = new TelegramBot(TELEGRAM_BOT_TOKEN, {
        polling: true,
        request: {
            agentOptions: {
                keepAlive: true,
                family: 4
            }
        } 
    });

    bot.onText(/\/start/, (msg) => {
        const chatId = msg.chat.id;
        let subscribers = loadSubscribers();

        if (!subscribers.includes(chatId)) {
            subscribers.push(chatId);
            saveSubscribers(subscribers);
            bot.sendMessage(chatId, "You have subscribed successfully!");
        } else {
            bot.sendMessage(chatId, "You have already been subscribed!");
        }
    });

    bot.on("polling_error", (error) => {
        console.error('[polling_error]', error.code, error.message);
        if (error.code == "EFATAL") {
            bot.stopPolling()
               .then(() => bot.startPolling())
               .catch(err => console.error("Error restarting polling:", err));
        }
    });
} else {
    console.log("⚠️ Telegram Bot відключено (токен не знайдено).");
}

const loadSubscribers = () => {
    try {
        const data = fs.readFileSync(__dirname + "/subscribers.json", "utf8");
        // console.log(data);
        return JSON.parse(data);
    } catch (error) {
        console.error("Error loading subsricbers: ", error);
        return [];
    }
}

const saveSubscribers = (subscribers) => {
    fs.writeFileSync(__dirname + "/subscribers.json", JSON.stringify(subscribers, null, 2));
}


export const getAllSubscribers = () => loadSubscribers();


export const sendContactMessage = async (req, res) => {
    
    const supabase = createSupabaseWithoutToken;
    
    const { name, email, message} = req.body;

    if (!name || !email || !message) {
        return res.status(400).json({ error: "All fields are required." });
    }

    const { data, error: dbError } = await supabase
        .from("contact_messages")
        .insert([{ name, email, message }]);

    if (dbError) {
        return res.status(400).json({
            error: "Error occurred while inserting data into Supabase:",
            dbError,
        });
    }

    // Prepare the email to notify the team
    const mailOptions = {
        from: email,
        replyTo: email,
        to: GMAIL_EMAIL,
        subject: "New Contact Message",
        text: `Name: ${name}\nEmail: ${email}\nMessage: ${message}`,
    };

    try {
        await pool.query(
            "INSERT INTO contact_messages (name, email, message) VALUES ($1, $2, $3)",
            [name, email, message]
        );

        // ... код відправки на пошту (transporter.sendMail)
        await transporter.sendMail(mailOptions);
        processNewContacts(); 
        return res.status(200).json({ message: "Message sent successfully." });
    } catch (error) {
        console.error("DB/Email Error:", error);
        return res.status(500).json({ error: "Failed to send message." });
    }
};


const sendToTelegram = async (message) => {
    // Якщо токена немає - просто виводимо в консоль і йдемо далі
    if (!TELEGRAM_BOT_TOKEN || TELEGRAM_BOT_TOKEN === "undefined") {
        console.log("✉️ [Імітація Telegram сповіщення]:", message);
        return;
    }

    const subscribers = getAllSubscribers();

    for (const chatId of subscribers) {
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
        const data = {
            chat_id: chatId,
            text: message,
        };

        try {
            await axios.post(url, data);
            console.log("Messages send to Telegram.");
        } catch (error) {
            console.error("Error while sending message to the Telegram: ", error);
        }
    }
};

const getNewContacts = async () => {
    try {
        const res = await pool.query("SELECT * FROM contact_messages ORDER BY created_at DESC LIMIT 1");
        return res.rows;
    } catch (error) {
        console.error("Error fetching contacts:", error);
        return [];
    }
};

export const processNewContacts = async () => {
    const contacts = await getNewContacts();
    console.log(contacts);
    if (!contacts || contacts.length === 0) {
        console.log("There's no new contacts");
        return;
    }

    contacts.forEach(async (contacts) => {
        const message = `
            You have recently received a new order. Please check the details.
            Name: ${contacts.name}
            Email: ${contacts.email}
            Message: ${contacts.message}
        `;
        await sendToTelegram(message);
    });
};

