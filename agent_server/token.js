import express from "express";
import dotenv from "dotenv";
import jwt from "jsonwebtoken";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/getToken", (req, res) => {
  try {
    const identity = req.query.identity || "flutter-user";
    const room = req.query.room || "test-room";

    const payload = {
      iss: process.env.LIVEKIT_API_KEY,   // API Key
      sub: identity,                       // unique identity for the participant
      exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour expiry
      grants: {
        roomJoin: true,                    // must be true
        room: room,                        // name of the room you want to join
        canPublish: true,                  // allow sending audio/video
        canPublishData: true,              // allow sending data messages
      },
    };

    const token = jwt.sign(payload, process.env.LIVEKIT_API_SECRET, { algorithm: "HS256" });

    res.json({ token });
    console.log(`✅ Token generated for ${identity} in room ${room}`);
  } catch (err) {
    console.error("❌ Failed to generate token:", err);
    res.status(500).json({ error: "Failed to generate token" });
  }
});

app.listen(PORT, () => {
  console.log(`✅ Token server running at http://localhost:${PORT}`);
});
