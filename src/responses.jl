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


using HttpCommon: Response, STATUS_CODES


function api_response_data(data)
    # response_data = dict(
    #     apiVersion = 1,
    #     context = data['context'],
    #     method = req.script_name,
    #     params = inputs,
    #     suggestions = suggestions,
    #     tracebacks = tracebacks_json,
    #     url = req.url.decode('utf-8'),
    #     value = reform_output_test_cases if data['reforms'] is not None else base_output_test_cases,
    #     variables = simulations_variables_json,
    #     )

  return merge(data, {
    "api_version" => 1,
  })
end


function bad_request(res::Response; errors = nothing)
  status_code = 400
  data = {
    "error" => [
      "code" => status_code,
      "errors" => errors,
      "message" => STATUS_CODES[status_code],
    ],
  }
  res.status = status_code
  response_data = api_response_data(data)
  return respond_json(res, data = response_data)
end


function respond_json(res::Response; data = nothing)
  res.headers["Content-Type"] = "application/json; charset=utf-8"
  if data !== nothing
    res.data = JSON.json(data)
  end
  return res
end
