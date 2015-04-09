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
  return handle(middleware(APIDataV1(response_data), JSONData), req, res)
end
