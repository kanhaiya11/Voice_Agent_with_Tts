import dotenv from "dotenv";
import { Worker, initializeLogger } from "@livekit/agents";
import googleTTS from "google-tts-api";
import fetch from "node-fetch";
import fs from "fs";

dotenv.config();
initializeLogger({ pretty: true, level: "info" });

// TTS helper
async function textToSpeech(text, filename) {
  const url = googleTTS.getAudioUrl(text, { lang: "en", slow: false, host: "https://translate.google.com" });
  const res = await fetch(url);
  const buffer = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filename, buffer);
  return filename;
}

// Create Worker with roomHandler — this immediately starts listening
new Worker({
  url: process.env.LIVEKIT_URL,
  apiKey: process.env.LIVEKIT_API_KEY,
  apiSecret: process.env.LIVEKIT_API_SECRET,

  roomHandler: async (room) => {
    console.log(`✅ Agent joined room: ${room.name}`);

    room.participants.forEach(p => console.log(`👤 Participant: ${p.identity}`));

    room.onParticipantConnected(p => console.log(`👤 Participant connected: ${p.identity}`));

    room.onTrackSubscribed(async (track, publication, participant) => {
      if (publication.kind !== "audio") return;
      console.log(`🎙 Received audio from ${participant.identity}`);

      // Mock STT
      const recognizedText = "Hello agent!";
      console.log(`📝 User said: ${recognizedText}`);

      // Mock reply
      const replyText = "Hi! This is a test voice reply.";

      const mp3File = await textToSpeech(replyText, "reply.mp3");

      await room.localParticipant.publishTrack(mp3File, { kind: "audio", name: "agent-voice" });
      console.log("🔊 Published voice reply to room");
    });
  },
});

console.log("🚀 Agent Worker initialized and running");
