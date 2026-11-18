import express from "express";
import { sendContactMessage } from "../controllers/getContactsContoller.js";
const router = express.Router();

router.post("/", sendContactMessage);

export default router;
