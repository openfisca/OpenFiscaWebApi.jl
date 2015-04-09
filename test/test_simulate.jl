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


const simulation_json_str = """
{
  "scenarios": [
    {
      "test_case": {
        "familles": [
          {
            "parents": ["ind0"]
          }
        ],
        "foyers_fiscaux": [
          {
            "declarants": ["ind0"]
          }
        ],
        "individus": [
          {
            "id": "ind0"
          }
        ],
        "menages": [
          {
            "personne_de_reference": "ind0"
          }
        ]
      },
      "period": "2013"
    }
  ]
}
"""


facts("simulate controller") do
  context("empty body") do
    res = handle_simulate_version_1(MeddleRequest(headers = json_headers, method = "POST"), Response())
    @fact res.status => 400
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    @fact isa(data, Dict) => true
    @fact haskey(data, "error") => true
  end
  context("wrong req Content-Type") do
    req = MeddleRequest(data = simulation_json_str, method = "POST")
    res = handle_simulate_version_1(req, Response())
    @fact res.status => 400
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    @fact isa(data, Dict) => true
    @fact haskey(data, "error") => true
    @fact isa(data["error"], Dict) => true
    @fact haskey(data["error"], "errors") => true
    @fact isa(data["error"]["errors"], Dict) => true
    @fact haskey(data["error"]["errors"], "content_type") => true
  end
  context("single individual") do
    req = MeddleRequest(data = simulation_json_str, headers = json_headers, method = "POST")
    res = handle_simulate_version_1(req, Response())
    @fact res.status => 200
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    @fact isa(data, Dict) => true
    @fact haskey(data, "error") => false
    @fact haskey(data, "value") => true
  end
end
