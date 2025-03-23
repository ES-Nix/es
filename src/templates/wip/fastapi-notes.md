

```bash
docker run -i --rm python:3.13 bash <<'COMMANDS'

pip install fastapi==0.115.8 httpx==0.28.1 pytest==8.3.4

cat << 'EOF' > script.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, validator, field_validator
from typing import Optional
from fastapi.testclient import TestClient
from unittest import mock
import pytest

app = FastAPI()

class SpecialNumber(BaseModel):
    special_number: Optional[int]

    @validator("special_number")
    def validate_special_number(cls, value):
        if value not in [3, 5]:
            raise ValueError("The field special_number only accepts 3 or 5.")
        return value

@app.patch("/define-special-number")
async def update_special_number(special_number_in: SpecialNumber):
    if special_number_in.special_number == 3:
        number = 10 * special_number_in.special_number
    elif special_number_in.special_number == 5:
        number = 15 * special_number_in.special_number
    else:
        raise HTTPException(status_code=400, detail="Invalid special_number!")
    return {"number": number}


def test_patch_mocked_validate_special_number_0():
    client = TestClient(app)
    response = client.patch("/define-special-number", json={"special_number": 3})

    assert response.status_code == 200
    assert response.json() == {"number": 30}

def test_patch_mocked_validate_special_number_1():
    client = TestClient(app)
    response = client.patch("/define-special-number", json={"special_number": 5})

    assert response.status_code == 200
    assert response.json() == {"number": 75}

def test_patch_mocked_validate_special_number_2():
    # Mock the `__init__` method of the Pydantic model to bypass validation
    with mock.patch.object(SpecialNumber, '__init__', lambda self, **kwargs: None):
        client = TestClient(app)
        response = client.patch("/define-special-number", json={"special_number": 9})

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid special_number!"

def test_patch_mocked_validate_special_number_3():
    with mock.patch.object(SpecialNumber, 'validate_special_number', lambda cls, value: value):
        client = TestClient(app)
        # Send a valid request that would normally pass the validation
        response = client.patch("/define-special-number", json={"special_number": 3})
        assert response.status_code == 200
        assert response.json() == {"number": 30}

        # Send a request that would normally fail validation (but won't because we mocked the validator)
        response = client.patch("/define-special-number", json={"special_number": 4})
        assert response.status_code == 400  # It shouldn't raise 422 because we've mocked the validation
        assert response.json()["detail"] == "Invalid special_number!"

def test_patch_mocked_validate_special_number_4():
    with mock.patch.object(SpecialNumber, 'validate_special_number', return_value=8):
        client = TestClient(app)
        # Send a valid request that would normally pass the validation
        response = client.patch("/define-special-number", json={"special_number": 3})
        assert response.status_code == 200
        assert response.json() == {"number": 30}

        # Send a request that would normally fail validation (but won't because we mocked the validator)
        response = client.patch("/define-special-number", json={"special_number": 4})
        assert response.status_code == 400  # It shouldn't raise 422 because we've mocked the validation
        assert response.json()["detail"] == "Invalid special_number!"

pytest.main()
EOF

pytest -v script.py
COMMANDS
```


```bash
cat << 'EOF' > script.py
from pydantic import BaseModel, validator, field_validator
from typing import Optional
from unittest import mock
import pytest


class SpecialNumber(BaseModel):
    special_number: Optional[int]

    @validator("special_number")
    def validate_special_number(cls, value):
        if value not in [3, 5]:
            raise ValueError("The field special_number only accepts 3 or 5.")
        return value

def process_special_number(special_number_in: SpecialNumber):
    if special_number_in == 3:
        number = 10 * special_number_in
    elif special_number_in == 5:
        number = 15 * special_number_in
    else:
        raise ValueError("Invalid special_number!")
    return {"number": number}


def test_patch_mocked_validate_special_number_0():
    result = process_special_number(special_number_in=3)
    assert result == {"number": 30}

def test_patch_mocked_validate_special_number_1():
    result = process_special_number(special_number_in=5)
    assert result == {"number": 75}

def test_patch_mocked_validate_special_number_2():
    result = process_special_number(special_number_in=9)
    assert result == {"number": 75}

pytest.main()
EOF

pytest -v script.py
```
