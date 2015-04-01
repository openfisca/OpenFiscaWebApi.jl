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
using OpenFiscaFrance


const DEFAULT_YEAR = 2013

const columns_tree = JSON.parsefile(joinpath(Pkg.dir("OpenFiscaWebApi"), "columns_tree.json"))


include("controllers/calculate.jl")
include("controllers/simulate.jl")
include("controllers/entities.jl")
include("controllers/fields.jl")
include("midwares.jl")


function make_app()
  app = Morsel.app()
  Morsel.with(app, CORS) do app
    Morsel.route(app, POST | OPTIONS, "/api/1/calculate", handle_calculate_version_1)
    Morsel.route(app, GET | OPTIONS, "/api/1/entities", handle_entities_version_1)
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
