from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class Dispositivo(Base):
    __tablename__ = 'dispositivos'
    id = Column(Integer, primary_key=True)
    ativo_numero = Column(Integer)
    modelo = Column(String)
    status = Column(String)
    imei1 = Column(String)

    def __repr__(self):
        return f"<Dispositivo id={self.id!r} ativo_numero={self.ativo_numero!r} modelo={self.modelo!r}>"

class Pessoa(Base):
    __tablename__ = 'pessoas'
    id = Column(Integer, primary_key=True)
    nome = Column(String)
    email = Column(String)

    def __repr__(self):
        return f"<Pessoa id={self.id!r} nome={self.nome!r}>"
