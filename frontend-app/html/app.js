// Konfigurasi endpoint - gunakan relative URLs via nginx proxy
const FARM_DATA_API = "/api";
const STORAGE_API = "/storage";
const DISPLAY_TIME_ZONE = "Asia/Jakarta";
const DISPLAY_LOCALE = "id-ID";

const metricCharts = {};
const actuatorUsage = [
    { name: "AC", percent: 34, className: "actuator-ac" },
    { name: "CO2", percent: 18, className: "actuator-co2" },
    { name: "Humidifier", percent: 27, className: "actuator-humidifier" },
    { name: "Lampu", percent: 21, className: "actuator-lamp" }
];
const chartTimeFormatter = new Intl.DateTimeFormat(DISPLAY_LOCALE, {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: DISPLAY_TIME_ZONE,
    hour12: false
});
const chartTooltipFormatter = new Intl.DateTimeFormat(DISPLAY_LOCALE, {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: DISPLAY_TIME_ZONE,
    hour12: false
});
const harvestDateFormatter = new Intl.DateTimeFormat(DISPLAY_LOCALE, {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: DISPLAY_TIME_ZONE
});
const minuteKeyFormatter = new Intl.DateTimeFormat("en-CA", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: DISPLAY_TIME_ZONE,
    hour12: false
});

// Fetch data terbaru untuk card
async function fetchLatestMetrics() {
    try {
        const res = await fetch(`${FARM_DATA_API}/metrics/latest`);
        const data = await res.json();
        if (data.temperature_c) {
            document.getElementById("temp").innerText = data.temperature_c;
            document.getElementById("hum").innerText = data.humidity_percent;
            document.getElementById("light").innerText = data.light_lux;
            document.getElementById("energy").innerText = data.energy_kwh;
        }
    } catch (err) {
        console.error("Error fetching latest metrics:", err);
    }
}

// Fetch harvest progress
async function fetchHarvestProgress() {
    try {
        const res = await fetch(`${FARM_DATA_API}/harvest-progress`);
        const data = await res.json();
        const percent = data.progress_percent || 0;
        const totalDays = data.expected_harvest_days || 0;
        const daysPassed = Math.max(0, data.days_passed || 0);
        const remainingDays = Math.max(0, totalDays - daysPassed);
        const stage = getHarvestStage(daysPassed, totalDays);

        document.getElementById("harvest-progress-bar").style.width = percent + "%";
        document.getElementById("harvest-progress-bar").innerText = percent + "%";
        document.getElementById("harvest-status").innerText = `${formatHarvestStatus(data.status)} - ${percent}% perjalanan tanam`;
        document.getElementById("harvest-day").innerText = totalDays ? `${daysPassed} / ${totalDays}` : `${daysPassed}`;
        document.getElementById("harvest-remaining").innerText = `${remainingDays} hari`;
        document.getElementById("harvest-stage").innerText = stage.name;
        document.getElementById("harvest-estimate").innerText = formatHarvestEstimate(data.planting_date, totalDays);
        document.getElementById("harvest-focus").innerText = stage.focus;
    } catch (err) {
        console.error(err);
    }
}

function formatHarvestStatus(status) {
    if (status === "harvest_ready") return "Siap panen";
    return "Masa pertumbuhan";
}

function getHarvestStage(daysPassed, totalDays) {
    if (totalDays > 0 && daysPassed >= totalDays) {
        return {
            name: "Siap Panen",
            focus: "Fokus hari ini: cek kualitas daun, rapikan laporan panen, dan siapkan jadwal pemanenan."
        };
    }

    if (daysPassed <= 7) {
        return {
            name: "Adaptasi Awal",
            focus: "Fokus hari ini: jaga media tetap lembab dan hindari perubahan suhu yang terlalu tajam."
        };
    }

    if (daysPassed <= 20) {
        return {
            name: "Vegetatif Awal",
            focus: "Fokus hari ini: stabilkan suhu 18-24°C, kelembaban 60-80%, dan pantau cahaya harian."
        };
    }

    if (daysPassed <= 40) {
        return {
            name: "Vegetatif Aktif",
            focus: "Fokus hari ini: pantau pertumbuhan daun, pastikan lampu dan humidifier bekerja konsisten."
        };
    }

    return {
        name: "Menjelang Panen",
        focus: "Fokus hari ini: pertahankan kondisi lingkungan stabil dan mulai cek kesiapan laporan panen."
    };
}

function formatHarvestEstimate(plantingDate, totalDays) {
    const date = parseDateOnlyAsUtc(plantingDate);
    if (!date || !totalDays) return "--";
    date.setUTCDate(date.getUTCDate() + totalDays);
    return harvestDateFormatter.format(date);
}

function parseDateOnlyAsUtc(value) {
    if (!value) return null;
    const parts = value.split("-").map(Number);
    if (parts.length !== 3 || parts.some(Number.isNaN)) return null;
    return new Date(Date.UTC(parts[0], parts[1] - 1, parts[2], 0, 0, 0));
}

function renderActuatorUsage() {
    const container = document.getElementById("actuator-usage");
    container.innerHTML = "";

    actuatorUsage.forEach(item => {
        const row = document.createElement("div");
        row.className = "actuator-row";

        const label = document.createElement("div");
        label.className = "actuator-label";
        label.innerHTML = `<span>${item.name}</span><strong>${item.percent}%</strong>`;

        const track = document.createElement("div");
        track.className = "actuator-track";

        const bar = document.createElement("div");
        bar.className = `actuator-bar ${item.className}`;
        bar.style.width = `${item.percent}%`;

        track.appendChild(bar);
        row.appendChild(label);
        row.appendChild(track);
        container.appendChild(row);
    });
}

// Fetch daily chart data
async function fetchDailyChart(date = null) {
    let url = `${FARM_DATA_API}/metrics/daily`;
    if (date) url += `?date_str=${date}`;
    try {
        const res = await fetch(url);
        const data = await res.json();
        if (!data.length) return;
        const chartData = bucketDataByLocalMinute(data);
        const labels = chartData.map(d => formatChartTime(d.time));
        const tooltipLabels = chartData.map(d => formatTooltipTime(d.time));

        renderMetricChart("temperatureChart", labels, tooltipLabels, "Suhu (°C)", smoothValues(chartData.map(d => d.temperature)), "#d32f2f", false);
        renderMetricChart("humidityChart", labels, tooltipLabels, "Kelembaban (%)", smoothValues(chartData.map(d => d.humidity)), "#1976d2", false);
        renderMetricChart("lightChart", labels, tooltipLabels, "Cahaya (lux)", smoothValues(chartData.map(d => d.light)), "#f9a825", true);
        renderMetricChart("energyChart", labels, tooltipLabels, "Energi (kWh)", smoothValues(chartData.map(d => d.energy)), "#388e3c", true);
    } catch (err) {
        console.error("Error fetching chart data:", err);
    }
}

function parseApiTime(value) {
    if (!value) return null;
    const hasTimeZone = /(?:Z|[+-]\d{2}:?\d{2})$/.test(value);
    return new Date(hasTimeZone ? value : `${value}Z`);
}

function formatChartTime(value) {
    const date = parseApiTime(value);
    return date ? chartTimeFormatter.format(date) : "";
}

function formatTooltipTime(value) {
    const date = parseApiTime(value);
    return date ? `${chartTooltipFormatter.format(date)} WIB` : "";
}

function bucketDataByLocalMinute(rows) {
    const buckets = new Map();
    rows.forEach(row => {
        const date = parseApiTime(row.time);
        if (!date) return;
        buckets.set(minuteKeyFormatter.format(date), row);
    });
    return Array.from(buckets.values());
}

function smoothValues(values, windowSize = 3) {
    return values.map((_, index) => {
        const start = Math.max(0, index - windowSize + 1);
        const sample = values.slice(start, index + 1);
        const average = sample.reduce((total, value) => total + value, 0) / sample.length;
        return Number(average.toFixed(2));
    });
}

function renderMetricChart(canvasId, labels, tooltipLabels, label, values, color, beginAtZero) {
    if (metricCharts[canvasId]) {
        metricCharts[canvasId].destroy();
    }

    const ctx = document.getElementById(canvasId).getContext("2d");
    metricCharts[canvasId] = new Chart(ctx, {
        type: "line",
        data: {
            labels: labels,
            datasets: [{
                label: label,
                data: values,
                borderColor: color,
                backgroundColor: `${color}22`,
                borderWidth: 2.5,
                fill: true,
                tension: 0.35,
                pointRadius: 0,
                pointHoverRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            layout: {
                padding: {
                    top: 4,
                    right: 12,
                    bottom: 0,
                    left: 4
                }
            },
            plugins: {
                legend: {
                    display: true,
                    labels: {
                        boxWidth: 42,
                        padding: 10
                    }
                },
                tooltip: {
                    callbacks: {
                        title: items => tooltipLabels[items[0].dataIndex] || ""
                    }
                }
            },
            scales: {
                x: {
                    ticks: {
                        autoSkip: true,
                        maxTicksLimit: 8,
                        maxRotation: 0,
                        minRotation: 0
                    }
                },
                y: {
                    beginAtZero: beginAtZero,
                    ticks: {
                        padding: 8
                    }
                }
            }
        }
    });
}

// File management (storage-service)
async function loadFileList() {
    try {
        const res = await fetch(`${STORAGE_API}/files`);
        const files = await res.json();
        const list = document.getElementById("fileList");
        list.innerHTML = "";
        files.forEach(file => {
            const li = document.createElement("li");
            const filename = document.createElement("span");
            filename.textContent = file;

            const actions = document.createElement("span");
            actions.className = "file-actions";

            const downloadLink = document.createElement("a");
            downloadLink.className = "download-btn";
            downloadLink.href = `${STORAGE_API}/files/${encodeURIComponent(file)}`;
            downloadLink.download = file;
            downloadLink.textContent = "Unduh";

            const deleteButton = document.createElement("button");
            deleteButton.className = "delete-btn";
            deleteButton.dataset.file = file;
            deleteButton.textContent = "Hapus";

            actions.appendChild(downloadLink);
            actions.appendChild(deleteButton);
            li.appendChild(filename);
            li.appendChild(actions);
            list.appendChild(li);
        });
        document.querySelectorAll(".delete-btn").forEach(btn => {
            btn.addEventListener("click", async (e) => {
                const filename = btn.dataset.file;
                await fetch(`${STORAGE_API}/files/${encodeURIComponent(filename)}`, { method: "DELETE" });
                loadFileList();
            });
        });
    } catch (err) {
        console.error("Error loading files:", err);
    }
}

document.getElementById("uploadForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    const fileInput = document.getElementById("fileInput");
    const file = fileInput.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append("file", file);
    try {
        await fetch(`${STORAGE_API}/upload`, { method: "POST", body: formData });
        loadFileList();
        fileInput.value = "";
    } catch (err) {
        console.error("Upload error:", err);
    }
});

// Initial load
fetchLatestMetrics();
fetchHarvestProgress();
renderActuatorUsage();
fetchDailyChart();
loadFileList();

// Refresh mengikuti interval sensor lokal.
setInterval(() => {
    fetchLatestMetrics();
    fetchHarvestProgress();
    fetchDailyChart();
}, 60000);
