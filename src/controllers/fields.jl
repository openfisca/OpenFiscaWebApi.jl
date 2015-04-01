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


function handle_fields_version_1(req::MeddleRequest, res::Response)
  @assert req.http_req.method == "GET"
  req.params[:api_version] = 1

  entities_role = filter(
    x -> !isempty(x),
    mapreduce(
      x -> [x.index_variable_name, x.role_variable_name],
      vcat,
      values(tax_benefit_system.entity_definition_by_name)
    )
  )
  input_variables_definition = filter(
    x -> x.formula === nothing && x.name ∉ entities_role,
    values(tax_benefit_system.variable_definition_by_name)
  )
  columns = [
    variable_definition.name => to_json(variable_definition)
    for variable_definition in input_variables_definition
  ]

  formulas_definition = filter(x -> x.formula !== nothing, values(tax_benefit_system.variable_definition_by_name))
  prestations = [
    variable_definition.name => to_json(variable_definition)
    for variable_definition in formulas_definition
  ]

  response_data = ["columns" => columns, "columns_tree" => columns_tree, "prestations" => prestations]
  return handle(middleware(APIData(response_data), JSONData), req, res)
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
    variable_definition_json["entity_name"] = variable_definition.entity_definition.name
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
