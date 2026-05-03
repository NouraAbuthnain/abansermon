import requests
import wave
import struct

wav_path = 'dummy.wav'
with wave.open(wav_path, 'wb') as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(16000)
    for _ in range(16000):
        wav_file.writeframesraw(struct.pack('<h', 0))

print("Testing WAV pretending to be WebM...")
with open(wav_path, 'rb') as f:
    res = requests.post('https://norahmt-aban-ai-backend.hf.space/translate-audio', files={'audio': ('chunk.webm', f, 'audio/webm')})
    print(res.status_code)

print("Testing REAL WebM (using a tiny base64 webm)")
import base64
# minimal webm file
webm_b64 = "GkXfo59ChoEBQveBAULygQRC84EIQoKEd2VibUKHgQJChYECGbgQBgQCGhABvwECA8WBAhkB8nEBs6EBAwGvE0BUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBVgQBUgQBTgQBV"
webm_bytes = base64.b64decode(webm_b64)
res = requests.post('https://norahmt-aban-ai-backend.hf.space/translate-audio', files={'audio': ('chunk.webm', webm_bytes, 'audio/webm')})
print(res.status_code)
