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


function handle_field_version_1(req::MeddleRequest, res::Response)
  @assert req.http_req.method == "GET"

  params_to_data = struct(
    [
      :variable => pipe(
        empty_to_nothing,
        test_in(tax_benefit_system.variable_definition_by_name),
        default("revdisp"),
      ),
    ],
  )
  data, error = Convertible(req.params) |> params_to_data |> to_value_error
  if error !== nothing
    return handle(middleware(BadRequest, APIDataV1(error), JSONData), req, res)
  end

  variable_definition = tax_benefit_system.variable_definition_by_name[data[:variable]]

  json_output = to_json(variable_definition)

  formula = variable_definition.formula
  if formula !== nothing
    source = string(Base.uncompressed_ast(formula.code).args[3])
    json_output["formula"] = [
      "line_number" => formula.code.line,
      "source" => source,
    ]
  end

  response_data = ["value" => json_output]
  return handle(middleware(APIDataV1(response_data), JSONData), req, res)
end
