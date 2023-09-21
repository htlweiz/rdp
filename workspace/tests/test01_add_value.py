"""Test the add value method from crud."""


import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from rdp.crud.crud import Crud, Base, Value, ValueType

#Create an in-memory database and set up the SQLAlchemy engine
engine = create_engine("sqlite:///:memory:")
Base.metadata.create_all(engine)

@pytest.fixture
def crud_instance():
    """Fixture that creates and returns a Crud instance for testing."""
    return Crud(engine)


def test_add_value_type(crud_instance):
    """Check if value types are added."""

    #Add a new value type to the database
    crud_instance.add_or_update_value_type(value_type_name="TestType", value_type_unit="TestUnit")

    #Retrieve all existing value types from the database
    value_types = crud_instance.get_value_types()

    #Assert that there is exactly one value type in the database
    assert len(value_types) == 1
    
    #Assert that the added value type has the expected name and unit
    assert value_types[0].type_name == "TestType"
    assert value_types[0].type_unit == "TestUnit" 


def test_add_value(crud_instance):
    """Check if values are added."""

    #Define values for a new data entry
    value_time = 12345
    value_type_id = 1
    value_value = 42.0

    #Add a new value type to the database 
    crud_instance.add_or_update_value_type(value_type_name="TestType", value_type_unit="TestUnit")

    #Add a new value entry to the database
    crud_instance.add_value(value_time, value_type_id, value_value)

    #Open a database session
    with Session(engine) as session:
        #Query the database for the added value entry
        db_value = session.query(Value).filter(Value.time == value_time).first()

        #Assert that the database entry exists
        assert db_value is not None
        
        #Assert that the time and value match the expected values
        assert db_value.time == value_time
        assert db_value.value == value_value
        
        #Assert that the associated value type ID matches the expected ID
        assert db_value.value_type.id == value_type_id
