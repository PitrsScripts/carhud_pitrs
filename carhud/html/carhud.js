window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'show') {
        document.getElementById('hud').classList.remove('hidden');
    } else if (data.action === 'hide') {
        document.getElementById('hud').classList.add('hidden');
    } else if (data.action === 'showSettings') {
        document.getElementById('settings').classList.remove('hidden');
        currentScale = data.scale || 1.0;
        document.getElementById('scale-value').textContent = currentScale.toFixed(1) + 'x';
        document.getElementById('hud').style.transform = `scale(${currentScale})`;
    } else if (data.action === 'update') {
        updateSpeed(data.speed, data.unit);
        updateFuel(data.fuel);
        updateEngine(data.engine);
        updateLimiter(data.limiter, data.limiterSpeed);
        updateCruise(data.cruise, data.cruiseSpeed);
    }
});

function updateSpeed(speed, unit) {
    const speedStr = speed.toString().padStart(3, '0');
    
    document.getElementById('digit1').textContent = speedStr[0];
    document.getElementById('digit2').textContent = speedStr[1];
    document.getElementById('digit3').textContent = speedStr[2];
    
    // Aktivuj pouze potřebné číslice
    document.getElementById('digit1').classList.toggle('active', speed >= 100);
    document.getElementById('digit2').classList.toggle('active', speed >= 10);
    document.getElementById('digit3').classList.add('active');
    
    document.getElementById('speed-unit').textContent = unit;
    
    const maxSpeed = unit === 'MPH' ? 200 : 300;
    const percentage = Math.min(speed / maxSpeed, 1);
    const dashOffset = 377 - (377 * percentage);
    
    document.getElementById('speed-arc').style.strokeDashoffset = dashOffset;
}

function updateFuel(fuel) {
    const fillPercentage = 100 - fuel;
    document.getElementById('fuel-fill').style.clipPath = `inset(${fillPercentage}% 0 0 0)`;
    document.getElementById('fuel-percent').textContent = fuel + '%';
}

function updateEngine(engine) {
    const fillPercentage = 100 - engine;
    document.getElementById('engine-fill').style.clipPath = `inset(${fillPercentage}% 0 0 0)`;
    document.getElementById('engine-percent').textContent = engine + '%';
}

let currentScale = 1.0;

function changeScale(delta) {
    currentScale = Math.max(0.5, Math.min(2.0, currentScale + delta));
    document.getElementById('hud').style.transform = `scale(${currentScale})`;
    document.getElementById('scale-value').textContent = currentScale.toFixed(1) + 'x';
    
    try {
        fetch(`https://${GetParentResourceName()}/saveScale`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ scale: currentScale })
        }).catch(error => {
            console.log('Scale save failed:', error);
        });
    } catch (error) {
        console.log('Scale save error:', error);
    }
}

function closeSettings() {
    document.getElementById('settings').classList.add('hidden');
    
    try {
        fetch(`https://${GetParentResourceName()}/closeSettings`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        }).catch(error => {
            console.log('Close settings failed:', error);
        });
    } catch (error) {
        console.log('Close settings error:', error);
    }
}

// Drag functionality
let isDragging = false;
let dragOffset = { x: 0, y: 0 };

document.addEventListener('mousedown', function(e) {
    const panel = document.querySelector('.settings-panel');
    if (panel && panel.contains(e.target)) {
        isDragging = true;
        const rect = panel.getBoundingClientRect();
        dragOffset.x = e.clientX - rect.left;
        dragOffset.y = e.clientY - rect.top;
        e.preventDefault();
    }
});

document.addEventListener('mousemove', function(e) {
    if (isDragging) {
        const settings = document.getElementById('settings');
        settings.style.left = (e.clientX - dragOffset.x) + 'px';
        settings.style.top = (e.clientY - dragOffset.y) + 'px';
        settings.style.transform = 'none';
    }
});

document.addEventListener('mouseup', function() {
    isDragging = false;
});

function updateLimiter(active, speed) {
    const limiter = document.getElementById('limiter');
    const speedDisplay = document.getElementById('limiter-speed');
    
    if (active) {
        limiter.classList.add('active');
        speedDisplay.textContent = speed;
    } else {
        limiter.classList.remove('active');
        speedDisplay.textContent = 'OFF';
    }
}

function updateCruise(active, speed) {
    const cruise = document.getElementById('cruise');
    const speedDisplay = document.getElementById('cruise-speed');
    
    if (active) {
        cruise.classList.add('active');
        speedDisplay.textContent = speed;
    } else {
        cruise.classList.remove('active');
        speedDisplay.textContent = 'OFF';
    }
}