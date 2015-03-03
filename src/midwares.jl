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


# Convinient methods

import Meddle: handle

handle(midware::Midware, req::MeddleRequest, res::Response) = handle(middleware(midware), req, res)


import Morsel: prepare_response

# Allow controllers to return response and midware stack tuple.
prepare_response(res_and_stack::(Response, MidwareStack), req::MeddleRequest, res::Response) =
  prepare_response(handle(res_and_stack[2], req, res_and_stack[1]), req, res)

# Allow controllers to return response and midware stack tuple.
prepare_response(res_and_midware::(Response, Midware), req::MeddleRequest, res::Response) =
  prepare_response(handle(res_and_midware[2], req, res_and_midware[1]), req, res)


# Level 1 midwares

function APIData(data::Dict)
  Midware() do req::MeddleRequest, res::Response
    function build_error_field()
      error_field = {
        "code" => res.status,
        "message" => STATUS_CODES[res.status],
      }
      if length(data) > 0
        error_field["errors"] = data
      end
      return error_field
    end
    const API_DATA = [
      "api_version" => req.params[:api_version],
      "method" => req.http_req.method,
    ]
    req.state[:response_data] = merge(
      Dict(),
      400 <= res.status <= 599 ? ["error" => build_error_field()] : data,
      API_DATA,
    )
    req, res
  end
end

APIData() = APIData(Dict())


CORS = Midware() do req::MeddleRequest, res::Response
  # Cf http://www.w3.org/TR/cors/#resource-processing-model
  const ORIGIN = get(req.http_req.headers, "Origin", nothing)
  if ORIGIN === nothing
    return req, res
  end
  headers = Headers()
  if req.http_req.method == "OPTIONS"
    method = get(req.http_req.headers, "Access-Control-Request-Method", nothing)
    if method === nothing
      return req, res
    end
    headers_name = get(req.http_req.headers, "Access-Control-Request-Headers", "")
    merge!(headers, [
      "Access-Control-Allow-Credentials" => "true",
      "Access-Control-Allow-Origin" => ORIGIN,
      "Access-Control-Max-Age" => "3628800",
      "Access-Control-Allow-Methods" => method,
      "Access-Control-Allow-Headers" => headers_name
    ])
    res = handle(NoContent, req, res)
    return respond(req, res)
  end
  merge!(headers, [
    "Access-Control-Allow-Credentials" => "true",
    "Access-Control-Allow-Origin" => ORIGIN,
    "Access-Control-Expose-Headers" => "WWW-Authenticate",
  ])
  merge!(res.headers, headers)
  return req, res
end


JSONData = Midware() do req::MeddleRequest, res::Response
  res.headers["Content-Type"] = "application/json; charset=utf-8"
  if haskey(req.state, :response_data)
    res.data = JSON.json(req.state[:response_data])
  end
  req, res
end


function Status(status::Int)
  Midware() do req::MeddleRequest, res::Response
    res.status = status
    req, res
  end
end


# Level 2 midwares

BadRequest = Status(400)


NoContent = Midware() do req::MeddleRequest, res::Response
  res = handle(Status(204), req, res)
  delete!(res.headers, "Content-Type")
  req, res
end


# Meddle.NotFound does not fit because it calls respond() which does not allow chaining with JSON midwares.
NotFound = Status(404)
