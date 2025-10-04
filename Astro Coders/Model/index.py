from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import pickle
import numpy as np
from datetime import datetime

app = Flask(__name__)
CORS(app)  # للسماح بالـ requests من أي domain

# تحميل الـ model
try:
    import joblib
    try:
        # الطريقة الأولى: joblib
        model = joblib.load('rf_Temp_model.pkl')
        print("✅ Model loaded successfully with joblib!")
    except:
        # الطريقة التانية: pickle مع encoding
        with open('rf_Temp_model.pkl', 'rb') as f:
            model = pickle.load(f, encoding='latin1')
        print("✅ Model loaded successfully with pickle!")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    model = None

@app.route('/')
def home():
    """صفحة HTML الرئيسية"""
    html_content = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌡️ التنبؤ بدرجة الحرارة</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 100%;
        }
        h1 {
            text-align: center;
            color: #667eea;
            margin-bottom: 30px;
            font-size: 2em;
        }
        .input-group { margin-bottom: 20px; }
        label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
        }
        input, select {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 16px;
        }
        input:focus, select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        button {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover { transform: translateY(-2px); }
        .result {
            margin-top: 30px;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            display: none;
        }
        .result.success {
            background: #d4edda;
            border: 2px solid #28a745;
            color: #155724;
        }
        .result.error {
            background: #f8d7da;
            border: 2px solid #dc3545;
            color: #721c24;
        }
        .temp-display {
            font-size: 3em;
            font-weight: bold;
            margin: 10px 0;
        }
        .loader {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
            display: none;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌡️ التنبؤ بدرجة الحرارة</h1>
        <form id="predictionForm">
            <div class="input-group">
                <label for="lat">📍 خط العرض (Latitude)</label>
                <input type="number" id="lat" step="0.01" value="28.75" required>
            </div>
            <div class="input-group">
                <label for="lon">📍 خط الطول (Longitude)</label>
                <input type="number" id="lon" step="0.01" value="30.50" required>
            </div>
            <div class="grid">
                <div class="input-group">
                    <label for="year">📅 السنة</label>
                    <input type="number" id="year" min="2020" max="2050" value="2028" required>
                </div>
                <div class="input-group">
                    <label for="month">📅 الشهر</label>
                    <select id="month" required>
                        <option value="1">يناير</option>
                        <option value="2">فبراير</option>
                        <option value="3">مارس</option>
                        <option value="4" selected>أبريل</option>
                        <option value="5">مايو</option>
                        <option value="6">يونيو</option>
                        <option value="7">يوليو</option>
                        <option value="8">أغسطس</option>
                        <option value="9">سبتمبر</option>
                        <option value="10">أكتوبر</option>
                        <option value="11">نوفمبر</option>
                        <option value="12">ديسمبر</option>
                    </select>
                </div>
            </div>
            <div class="input-group">
                <label for="day">📅 اليوم</label>
                <input type="number" id="day" min="1" max="31" value="3" required>
            </div>
            <button type="submit">🔮 تنبؤ بدرجة الحرارة</button>
        </form>
        <div class="loader" id="loader"></div>
        <div class="result" id="result"></div>
    </div>
    <script>
        const form = document.getElementById('predictionForm');
        const loader = document.getElementById('loader');
        const result = document.getElementById('result');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            result.style.display = 'none';
            loader.style.display = 'block';
            const data = {
                lat: parseFloat(document.getElementById('lat').value),
                lon: parseFloat(document.getElementById('lon').value),
                year: parseInt(document.getElementById('year').value),
                month: parseInt(document.getElementById('month').value),
                day: parseInt(document.getElementById('day').value)
            };
            try {
                const response = await fetch('/predict', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                const responseData = await response.json();
                loader.style.display = 'none';
                if (responseData.success) {
                    result.className = 'result success';
                    result.innerHTML = `
                        <div class="temp-display">${responseData.temperature}°C</div>
                        <p><strong>📍 الموقع:</strong> ${responseData.location}</p>
                        <p><strong>📅 التاريخ:</strong> ${responseData.date}</p>
                    `;
                    result.style.display = 'block';
                } else {
                    throw new Error(responseData.error);
                }
            } catch (error) {
                loader.style.display = 'none';
                result.className = 'result error';
                result.innerHTML = `<p><strong>❌ حدث خطأ:</strong></p><p>${error.message}</p>`;
                result.style.display = 'block';
            }
        });
    </script>
</body>
</html>'''
    return html_content

@app.route('/predict', methods=['POST'])
def predict():
    """API endpoint للتنبؤ"""
    try:
        data = request.get_json()
        
        # استخراج البيانات
        lat = float(data['lat'])
        lon = float(data['lon'])
        year = int(data['year'])
        month = int(data['month'])
        day = int(data['day'])
        
        # حساب day_of_year (يوم السنة)
        date_obj = datetime(year, month, day)
        day_of_year = date_obj.timetuple().tm_yday
        
        # تجهيز البيانات - جرب الترتيبات المختلفة
        # الترتيب 1: مع day_of_year
        input_data = np.array([[lat, lon, year, month, day, day_of_year]])
        
        # لو ما اشتغلش، جرب واحد من دول:
        # input_data = np.array([[lat, lon, day, month, year, day_of_year]])
        # input_data = np.array([[year, month, day, day_of_year, lat, lon]])
        
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # التنبؤ
        prediction = model.predict(input_data)[0]
        
        return jsonify({
            'success': True,
            'temperature': round(float(prediction), 2),
            'location': f"{lat}°N, {lon}°E",
            'date': f"{day}/{month}/{year}"
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

@app.route('/health')
def health():
    """للتحقق من أن الـ API شغال"""
    return jsonify({'status': 'ok', 'model_loaded': model is not None})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)