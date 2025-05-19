import uvicorn


from fastapi import FastAPI
from scipy import optimize


app = FastAPI()

@app.get("/")
async def root():
    def f(x):
        return x**3 - 1

    def fprime1(x):
        return 3 * x**2
    
    def fprime2(x):
        return 6 * x

    # https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.newton.html
    result = optimize.newton(f, 1.5, fprime=fprime1, fprime2=fprime2)
    expected = 1.0

    assert result == expected, f"Expected {expected}, got {result}"

    return {"message": f"Hello world {result}"}

def start():
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=5000,
        reload=True
    )


if __name__ == '__main__':
    print("Starting FastAPI server...")
    start()
