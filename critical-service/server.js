const express = require("express");
const app = express();

const PORT = 8080;
let FAILURE_MODE = "off";

app.get("/status", async (req, res) => {
    if (FAILURE_MODE === "error") {
        return res
            .status(500)
            .json({ status: "ERROR", message: "Service in error mode" });
    }

    if (FAILURE_MODE === "slow") {
        await new Promise((resolve) => setTimeout(resolve, 1000));
    }

    res.status(200).json({ status: "OK" });
});

app.get("/set_failure_mode/:mode", (req, res) => {
    FAILURE_MODE = req.params.mode;
    res.json({ result: "mode set", mode: req.params.mode });
});

app.get("/get_failure_mode", (req, res) => {
    res.json({ mode: FAILURE_MODE });
});

app.listen(PORT, () => {
    console.log(
        `Critical Service running on port ${PORT}, mode: ${FAILURE_MODE}`,
    );
});
