const express = require("express");
const { exec } = require("child_process");
const app = express();

const PORT = 5001;

app.use(express.json());

/**
 * POST Endpoint. When a request is received (in this example project the
 * request will come from the 'monitor-service'), 'admin-service' will trigger
 * a docker command to restart 'critical-service'.
 */
app.post("/restart_service", (req, res) => {
    const service = req.body.service;
    if (!service) {
        return res.status(400).json({ result: "Service not set" });
    }

    console.log(`Restarting ${service}`);
    exec(`docker restart ${service}`, (error) => {
        if (error) {
            console.error(`Restart failed: ${error.message}`);
            return res.status(500).json({ result: "failed", service, error: error.message });
        }

        console.log(`Restarted service: ${service}`);
        res.json({ result: "restarted", service });
    });
});

app.listen(PORT, () => {
    console.log(`Admin Service running on port ${PORT}`);
});
