import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from langchain_chroma import Chroma
import google.generativeai as genai
from utils.embedding import get_embedding_function
from utils.extract_zones import extract_left_palm_zones, extract_back_left_hand_zones, extract_seeds
import dotenv

dotenv.load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

app = Flask(__name__)
CORS(app)

embedding_function = get_embedding_function()
db = Chroma(persist_directory="chroma", embedding_function=embedding_function)
generation_config = genai.GenerationConfig(
    temperature=0.2,
    top_p=0.8,
    top_k=5,
)
model = genai.GenerativeModel(
    "gemini-2.5-flash-preview-05-20",
    generation_config=generation_config,
)


@app.route("/ask", methods=["POST"])
def ask():
    print("Received request")
    data = request.get_json()
    print("Request data:", data)
    query_text = data.get("question", "")

    try:
        results = db.similarity_search_with_relevance_scores(query_text, k=4)
        for i, (doc, score) in enumerate(results, 1):
            print(f"Result {i}: Score = {score}")
            print(f"Document {i} metadata: {doc.metadata}")

        if not results:
            return jsonify({"answer": "I don't have enough information to answer that question."})

        context_text = "\n\n".join([doc.page_content for doc, _ in results])
        print("Context text:", context_text)

        prompt = f"""
        You are a Su Jok therapy expert. Answer the user's question based on the context and follow these rules:
        - Do NOT begin with "Answer:"
        - Always provide a helpful, accurate answer
        - Use the context to inform your response
        - When asked about seeds, talk about the seeds mentioned below
        - Determine if the user's question is:
            a) About Su Jok theory → Use TYPE 1 format
            b) About symptoms or treatment → Use TYPE 2 format
        - Do NOT mention the type of question in your response
        - ALWAYS Respond in the same language as the question
        - Remember these principles:
            1. On both the palm and back of the hand:
                a) Index finger corresponds to the left arm
                b) Middle finger corresponds to the left leg
                c) Ring finger corresponds to the right leg
                d) Little finger corresponds to the right arm
                e) The base of the fingers correspond to the shoulders/hips
                f) The middle of the fingers correspond to the elbows/knees
                g) The tips of the fingers correspond to the wrists/ankles
            2. On the palm only and NOT on the back of the hand:
                a) Base of Thumb corresponds to the neck and Distal Thumb corresponds to the head
                b) Thenar eminence corresponds to the chest
                c) Central palm corresponds to the abdomen
        - Format the response using the following structure:
            Start with a short 1–2 sentence explanation of the topic.
            If treatment is required, include the exact corresponding zones.
            Specify the treatment instructions (seed placement, massage method, etc.)
            [Only for TYPE 2 format] Add this line: Left hand palm: [exact zone names separated by commas]
            [Only for TYPE 2 format] Add this line: Back of left hand: [exact zone name separated by commas]
            [Only for TYPE 2 format] Add this line: Seeds to use: [exact seed names separated by commas]
            If any of the lines above are not applicable, DO NOT include them.
        - Use the EXACT names from below and ALWAYS have this part in ENGLISH:
            1. For the left hand palm: Central Palm, Thenar Eminence, Base of Thumb, Distal Thumb, Base of Index Finger, 
            Middle of Index Finger, Tip of Index Finger, Base of Middle Finger, Middle of Middle Finger, Tip of Middle Finger,
            Base of Ring Finger, Middle of Ring Finger, Tip of Ring Finger, Base of Little Finger, Middle of Little Finger,
            Tip of Little Finger
            2. For the back of the left hand: Base of Index Finger, Middle of Index Finger, Tip of Index Finger,
            Base of Middle Finger, Middle of Middle Finger, Tip of Middle Finger, Base of Ring Finger, Middle of Ring Finger,
            Tip of Ring Finger, Base of Little Finger, Middle of Little Finger, Tip of Little Finger
            3. For the seeds use ONLY these and keep their names EXACTLY like here: 
            Buckwheat, Pepper, Apple, Pumpkin, Guelder Rose, Grape, Mustard, Radish, Sunflower, Walnut, Black Seeds
        Context:
        {context_text}
        User Question:
        {query_text}
        """

        response = model.generate_content(prompt)
        print("Sending response:", response.text)

        left_palm_zones = extract_left_palm_zones(response.text)
        back_left_hand_zones = extract_back_left_hand_zones(response.text)
        seeds = extract_seeds(response.text)

        print("Extracted zones and seeds:",
              {"left_palm_zone": left_palm_zones, "back_left_hand_zone": back_left_hand_zones, "seeds": seeds})

        return jsonify({
            "answer": response.text,
            "left_palm_zones": left_palm_zones,
            "back_left_hand_zones": back_left_hand_zones,
            "seeds": seeds
        })

    except Exception as e:
        print(f"Error in ask route: {e}")
        return jsonify({"answer": f"Error: {str(e)}"}), 500


def warmup():
    print("Warming up the model...")
    try:
        db.similarity_search_with_relevance_scores("Warm up", k=1)
        print("Model warmed up successfully.")
    except Exception as e:
        print(f"Error during warmup: {e}")


if __name__ == "__main__":
    warmup()
    app.run(debug=True, use_reloader=False, port=8000)
