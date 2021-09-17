defmodule TransigoAdmin.DataLayerTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.DataLayer

  test "generates a valid uid" do
    uid = DataLayer.generate_uid("exp")
    assert "T" == String.slice(uid, 0, 1)
    assert true = DataLayer.check_uid(uid, "exp")
  end
end
