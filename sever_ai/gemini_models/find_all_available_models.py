import google.generativeai as genai
import os
import dotenv

dotenv.load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

for model in genai.list_models():
    print(f" Name: {model.name}")