from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query
from sqlalchemy import text
from sqlmodel import Session, select
from model import Operator
from config import get_session, DATABASE_URL, APP_PORT
import uvicorn

print(f"Using database URL: {DATABASE_URL}")
app = FastAPI()

# SessionDep = Annotated[Session, Depends(get_session)]

@app.get("/")
def read_root():
    return {"messsage": "A simple fast api project to test the deployment"}

@app.get("/health")
def health_check(db: Session = Depends(get_session)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@app.post("/operators")
def create_operator(operator: Operator, db: Session = Depends(get_session)) -> Operator:
    db.add(operator)
    db.commit()
    db.refresh(operator)
    return operator


@app.get("/operators")
def read_operators(
    db: Session = Depends(get_session),
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
) -> list[Operator]:
    operators = db.exec(select(Operator)).all()
    return operators


@app.get("/operators/{operator_id}")
def read_operator(operator_id: int, db: Session = Depends(get_session)) -> Operator:
    operator = db.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Operator not found")
    return operator


@app.delete("/operators/{operator_id}")
def delete_operator(operator_id: int, db: Session = Depends(get_session)):
    operator = db.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Operator not found")
    db.delete(operator)
    db.commit()
    return {"ok": True}

@app.put("/operators/{operator_id}")
def update_operator(
    operator_id: int, operator: Operator, db: Session = Depends(get_session)
) -> Operator:
    db_operator = db.get(Operator, operator_id)
    if not db_operator:
        raise HTTPException(status_code=404, detail="Operator not found")

    operator_data = operator.dict(exclude_unset=True)
    for key, value in operator_data.items():
        setattr(db_operator, key, value)

    db.add(db_operator)
    db.commit()
    db.refresh(db_operator)
    return db_operator

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=int(APP_PORT), reload=True)
