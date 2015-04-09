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


facts("fields controller") do
    res = handle_fields_version_1(MeddleRequest(method = "GET"), Response())
    @fact res.status => 200
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    @fact isa(data, Dict) => true
    @fact haskey(data, "columns") => true
    @fact isa(data["columns"], Dict) => true
    @fact length(data["columns"]) > 0 => true
    @fact haskey(data, "columns_tree") => true
    @fact isa(data["columns_tree"], Dict) => true
    @fact length(data["columns_tree"]) > 0 => true
end
