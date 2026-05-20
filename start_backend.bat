@echo off
set PYTHONPATH=D:\academic\8th semester\Extraprojects\shikkhaai-backend
cd /d "D:\academic\8th semester\Extraprojects\shikkhaai-backend\backend"
"D:\academic\8th semester\Extraprojects\shikkhaai-backend\.venv\Scripts\uvicorn.exe" app.main:app --port 8000 > "..\server.log" 2>&1
