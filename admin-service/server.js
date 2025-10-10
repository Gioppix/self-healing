const express = require("express");
const { exec } = require("child_process");
const app = express();

const PORT = 5001;

app.use(express.json());

app.post("/restart_service", (req, res) => {
    const service = req.body.service || "critical";

    exec(`docker restart ${service}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Restart failed: ${error.message}`);
            return res.status(500).json({ result: "failed", service, error: error.message });
        }

        console.log(`Restarted service: ${service}`);
        res.json({ result: "restarted", service });
    });
});

app.get("/health", (req, res) => {
    res.json({ status: "OK" });
});

app.listen(PORT, () => {
    console.log(`Admin Service running on port ${PORT}`);
});
