from fastapi import FastAPI # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import pickle
import numpy as np # type: ignore
import tensorflow.lite as tflite # type: ignore
from pydantic import BaseModel # type: ignore
from fastapi import HTTPException # type: ignore



# Initialize FastAPI app
app = FastAPI()

# ✅ Ajouter le CORS directement après l'init de FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Pickle Models
with open("models/act_phy.pickle", "rb") as f:
    activity_model = pickle.load(f)

with open("models/diabete.pickle", "rb") as f:
    diabetes_model = pickle.load(f)

with open("models/heart_rate.pickle", "rb") as f:
    heart_rate_model = pickle.load(f)

with open("models/hypertension.pickle", "rb") as f:
    hypertension_model = pickle.load(f)

# Load TensorFlow Lite Model (stability1.tflite)
def load_tflite_model(model_path):
    interpreter = tflite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    return interpreter

stability_model = load_tflite_model("models/stability1.tflite")

# Debugging: Check expected input shape
print("TFLite expected input shape:", stability_model.get_input_details()[0]['shape'])

# Define Input Data Structure
class InputData(BaseModel):
    features: list[float]

# Test API
@app.get("/")
def read_root():
    return {"message": "VitalTrack AI API is running!"}

# Pickle Model Endpoints
@app.post("/predict/activity")
def predict_activity(data: InputData):
    X = np.array(data.features).reshape(1, -1)
    prediction = activity_model.predict(X)
    
    # Assurez-vous que la sortie est un entier (au cas où ce serait un float)
    predicted_class = int(prediction[0])
    
    # Mapping des activités
    activity_mapping = {0: "Walking", 1: "Jogging", 2: "Cycling"}
    predicted_activity = activity_mapping.get(predicted_class, "Unknown")
    
    return {
        "activity_prediction": predicted_activity
    }


@app.post("/predict/diabetes") 
def predict_diabetes(data: InputData):
    X = np.array(data.features).reshape(1, -1)
    prediction = diabetes_model.predict(X)
    
    # Access the first element of the prediction array
    predicted_value = prediction[0]
    
    # Return the predicted value as a float (or you can round it as needed)
    return {"diabetes_prediction": f"{predicted_value:.2f}"}


@app.post("/predict/heart_rate")
def predict_heart_rate(data: InputData):
    X = np.array(data.features).reshape(1, -1)
    prediction = heart_rate_model.predict(X)
    
    # ✅ Extraire la valeur
    predicted_value = float(prediction[0])  
    
    # ✅ Arrondir à 2 chiffres
    predicted_value = round(predicted_value, 2)
    
    # ✅ Retourner avec l'unité bpm
    return {"heart_rate_prediction": f"{predicted_value} bpm"}


@app.post("/predict/hypertension")
def predict_hypertension(data: InputData):
    X = np.array(data.features).reshape(1, -1)
    prediction = hypertension_model.predict(X)
    predicted_value = prediction.tolist()[0]  # Convertir en valeur unique

    # Fonction pour classer la pression artérielle
    def blood_pressure_category(value):
        if 60 <= value < 90:
            return 'PA Hypotension'
        elif 90 <= value < 120:
            return 'PA optimale'
        elif 120 <= value < 130:
            return 'PA normale'
        elif 130 <= value < 140:
            return 'PA normale Haute'
        else:
            if 140 <= value < 160:
                return 'PA Hypertension - GRADE 1'
            elif 160 <= value < 180:
                return 'PA Hypertension - GRADE 2'
            else:
                return 'PA Hypertension - GRADE 3'

    category = blood_pressure_category(predicted_value)

    return {
        "hypertension_prediction": predicted_value,
        "blood_pressure_category": category
    }


# TensorFlow Lite Prediction Function
def predict_tflite(interpreter, data):
    input_tensor_index = interpreter.get_input_details()[0]['index']
    output_tensor_index = interpreter.get_output_details()[0]['index']

    # Convert input to correct format
    input_data = np.array(data.features, dtype=np.float32).reshape(1, -1)
    
    print("Input data to model:", input_data)  # Debugging
    
    interpreter.set_tensor(input_tensor_index, input_data)
    interpreter.invoke()
    
    output = interpreter.get_tensor(output_tensor_index)
    print("Raw model output:", output)  # Debugging

    return output.tolist()

# Stability Prediction using TFLite
@app.post("/predict/stability1")
def predict_stability(data: InputData):
    try:
        # 🧠 Predict with TFLite
        prediction = predict_tflite(stability_model, data)
        prediction = prediction[0]  # Get single result
        predicted_class = int(np.argmax(prediction))  # Get index of highest probability

        # 🌡️ Get actual input values
        heart_rate = data.features[1]
        spo2 = data.features[2]
        age = data.features[0]  # Assuming age is the first feature in the list

        # 🩺 Evaluate heart rate stability based on age
        if age <= 2 and 100 <= heart_rate <= 160:
            heart_status = "heart rate stable"
        elif 2 < age <= 6 and 70 <= heart_rate <= 120:
            heart_status = "heart rate stable"
        elif 6 < age <= 12 and 60 <= heart_rate <= 110:
            heart_status = "heart rate stable"
        elif 12 < age <= 18 and 50 <= heart_rate <= 100:
            heart_status = "heart rate stable"
        elif 18 < age and 60 <= heart_rate <= 100:
            heart_status = "heart rate stable"
        else:
            heart_status = "heart rate unstable"

        # 🩺 Evaluate oxygen stability
        if age <= 65 and 95 < spo2 < 100:
            spo2_status = "oxygen stable"
        elif spo2 >= 95:
            spo2_status = "oxygen stable"
        else:
            spo2_status = "oxygen unstable"

        # 🧾 Final message depending on model + real values
        labels = ["Stable", "Unstable", "Grave"]
        label = labels[predicted_class]
        message = f"{label}"

        return {"stability_prediction": message}

    except Exception as e:
        print(f"❌ Error in stability prediction: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Error in stability prediction: {str(e)}")




