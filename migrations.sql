-- tinysurveylicious - a tiny web survey application
-- Copyright (C) Eskild Hustvedt 2016
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--
-- This file is in the Mojo::SQLite::Migrations format

-- 1 up
CREATE TABLE responses (
    entryid INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT
);
CREATE TABLE authtokens (
    tokenid INTEGER PRIMARY KEY AUTOINCREMENT,
    token VARCHAR(254),
    valid INTEGER(1) DEFAULT 1
);
-- 1 down
DROP TABLE responses;
DROP TABLE authtokens;
