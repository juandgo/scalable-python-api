import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlmodel.pool import StaticPool

from blazing.main import app  # Ajusta la importación a tu archivo principal
from blazing.db import get_session # O la función que provee la sesión

# 1. Configuración de Base de Datos en Memoria para Tests
@pytest.fixture(name="session")
def session_fixture():
    engine = create_engine(
        "sqlite://", 
        connect_args={"check_same_thread": False}, 
        poolclass=StaticPool
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session

@pytest.fixture(name="client")
def client_fixture(session: Session):
    # Sobrescribimos la dependencia de la sesión para que use la de memoria
    def get_session_override():
        return session
    
    # app.dependency_overrides[get_session] = get_session_override
    with TestClient(app) as client:
        yield client

# --- PRUEBAS ---

def test_create_pokemon(client: TestClient):
    response = client.post(
        "/pokemon/",
        json={"name": "Pikachu", "type": "Electric", "level": 25}
    )
    data = response.json()

    assert response.status_code == 200
    assert data["name"] == "Pikachu"
    assert "id" in data

def test_get_pokemon(client: TestClient):
    # Primero creamos uno
    create_res = client.post("/pokemon/", json={"name": "Charmander", "type": "Fire"})
    pokemon_id = create_res.json()["id"]

    # Luego lo consultamos
    response = client.get(f"/pokemon/{pokemon_id}")
    assert response.status_code == 200
    assert response.json()["name"] == "Charmander"

def test_get_pokemon_not_found(client: TestClient):
    response = client.get("/pokemon/999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Pokemon not found"

def test_list_pokemon(client: TestClient):
    client.post("/pokemon/", json={"name": "Bulbasaur", "type": "Grass"})
    client.post("/pokemon/", json={"name": "Squirtle", "type": "Water"})

    response = client.get("/pokemon/")
    data = response.json()

    assert response.status_code == 200
    assert len(data) >= 2

def test_delete_pokemon(client: TestClient):
    # Crear
    create_res = client.post("/pokemon/", json={"name": "Pidgey", "type": "Normal"})
    pokemon_id = create_res.json()["id"]

    # Borrar
    delete_res = client.delete(f"/pokemon/{pokemon_id}")
    assert delete_res.status_code == 200
    assert delete_res.json() == {"ok": True}

    # Verificar que ya no existe
    get_res = client.get(f"/pokemon/{pokemon_id}")
    assert get_res.status_code == 404