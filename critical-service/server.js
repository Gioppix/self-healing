const express = require("express");
const app = express();

const PORT = 8080;

const ALLOWED_MODES = ["off", "error", "slow"];
let FAILURE_MODE = "off";
let memory = 0;

// GET Endpoint used for checking the Critical Service status.
app.get("/status", async (req, res) => {
    switch (FAILURE_MODE) {
        case "error":
            return res.status(500).json({ status: "ERROR", message: "Service in error mode", memory: memory});
        case "slow":
            await new Promise((resolve) => setTimeout(resolve, 1000));
            break;
    }

    memory += 100;

    res.status(200).json({ status: "OK", memory: memory});
});

/**
 * GET Endpoint used for setting the Critical Service failure mode.
 * Technically should be a POST endpoint but we chose this option for practicality.
 */
app.get("/set_failure_mode/:mode", (req, res) => {
    if (!ALLOWED_MODES.includes(req.params.mode)) {
        console.error(`Invalid failure mode attempted: ${req.params.mode}`);
        return res.status(400).json({ error: "Invalid failure mode", allowed: ALLOWED_MODES });
    }

    FAILURE_MODE = req.params.mode;
    res.json({ result: "mode set", mode: req.params.mode });
});

// GET Endpoint used for getting current service failure mode.
app.get("/get_failure_mode", (req, res) => {
    res.json({ mode: FAILURE_MODE });
});

app.listen(PORT, () => {
    console.log(`Critical Service running on port ${PORT}, mode: ${FAILURE_MODE}`);
});
