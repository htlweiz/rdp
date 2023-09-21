""""Test the get value types method from crud."""


import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from rdp.crud.crud import Crud, Base, Value, ValueType

# Create an in-memory database and set up the SQLAlchemy engine
engine = create_engine("sqlite:///:memory:")
Base.metadata.create_all(engine)

@pytest.fixture
def crud_instance():
    """Fixture that creates and returns a Crud instance for testing."""
    return Crud(engine)

def test_get_value_type_existing_value_type(crud_instance):
    """Test if get_value_type returns the correct ValueType object for an existing value type."""

    #Add a value type to the database
    crud_instance.add_or_update_value_type(value_type_name="TestType", value_type_unit="TestUnit")

    #Retrieve the ID of the added value type
    value_type_id = crud_instance.get_value_types()[0].id
    
    #Call get_value_type to retrieve the value type by its ID
    value_type = crud_instance.get_value_type(value_type_id)

    #Assert that the returned value type has the expected name and unit
    assert value_type.type_name == "TestType"
    assert value_type.type_unit == "TestUnit"
