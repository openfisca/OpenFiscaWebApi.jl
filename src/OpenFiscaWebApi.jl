# OpenFisca -- A versatile microsimulation software
# By: OpenFisca Team <contact@openfisca.fr>
#
# Copyright (C) 2011, 2012, 2013, 2014, 2015 OpenFisca Team
# https://github.com/openfisca
#
# This file is part of OpenFisca.
#
# OpenFisca is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# OpenFisca is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



module OpenFiscaWebApi


export handle_calculate_version_1,
  handle_entities_version_1,
  handle_field_version_1,
  handle_fields_version_1,
  handle_simulate_version_1,
  make_app,
  prepare_response,
  start


using Biryani
using Biryani.JsonConverters
using Dates
using HttpCommon
import JSON
using Meddle
import Morsel

using OpenFiscaCore


const columns_tree = JSON.parsefile(joinpath(Pkg.dir("OpenFiscaWebApi"), "columns_tree.json"))


function to_json(entity_definition::EntityDefinition)
  # ucfirst is used for Python API compatibility.
  entity_json = (String => Any)["label" => ucfirst(entity_definition.label)]
  if entity_definition.is_person
    entity_json["isPersonsEntity"] = entity_definition.is_person
  else
    merge!(entity_json, [
      "maxCardinalityByRoleKey" => entity_definition.max_persons_by_role_name,
      "roles" => entity_definition.roles_name,
      "labelByRoleKey" => [
        role_name => ucfirst(label)
        for (role_name, label) in entity_definition.label_by_role_name
      ]
    ])
  end
  return entity_json
end

function to_json(variable_definition::VariableDefinition)
  variable_definition_json = (String => Any)[
    "cell_type" => variable_definition.cell_type,
    "label" => variable_definition.label,
    "name" => variable_definition.name,
  ]
  if variable_definition.cerfa_field !== nothing
    variable_definition_json["cerfa_field"] = variable_definition.cerfa_field
  end
  if variable_definition.cell_format !== nothing
    variable_definition_json["cell_format"] = variable_definition.cell_format
  end
  if variable_definition.cell_default !== nothing
    variable_definition_json["default"] = variable_definition.cell_default
  end
  if variable_definition.entity_definition !== nothing
    variable_definition_json["entity"] = variable_definition.entity_definition.name
  end
  if variable_definition.start_date !== nothing
    variable_definition_json["start_date"] = variable_definition.start_date  # TODO isoformat
  end
  if variable_definition.stop_date !== nothing
    variable_definition_json["stop_date"] = variable_definition.stop_date  # TODO isoformat
  end
  if variable_definition.url !== nothing
    variable_definition_json["url"] = variable_definition.url
  end
  return variable_definition_json
end


include("controllers/calculate.jl")
include("controllers/simulate.jl")
include("controllers/entities.jl")
include("controllers/field.jl")
include("controllers/fields.jl")
include("midwares.jl")


function make_app()
  app = Morsel.app()
  Morsel.with(app, CORS) do app
    Morsel.route(app, POST | OPTIONS, "/api/1/calculate", handle_calculate_version_1)
    Morsel.route(app, GET | OPTIONS, "/api/1/entities", handle_entities_version_1)
    Morsel.route(app, GET | OPTIONS, "/api/1/field", handle_field_version_1)
    Morsel.route(app, GET | OPTIONS, "/api/1/fields", handle_fields_version_1)
    Morsel.route(app, POST | OPTIONS, "/api/1/simulate", handle_simulate_version_1)
  end
  return app
end


function start(port::Integer)
  app = make_app()
  Morsel.start(app, port)
end


end # module
