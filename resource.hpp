/*
 * Copyright (c) 2017, 2018 Florian Jung
 *
 * This file is part of factorio-bot.
 *
 * factorio-bot is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License,
 * version 3, as published by the Free Software Foundation.
 *
 * factorio-bot is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with factorio-bot. If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include <string>
#include <memory>
#include <unordered_map>
#include <vector>
#include <cassert>

#include "pos.hpp"
#include "area.hpp"
#include "entity.h"

struct ResourcePatch;

constexpr int NOT_YET_ASSIGNED = 0; // TODO FIXME

struct Resource
{
	enum type_t
	{
		NONE = 0,
		COAL,
		IRON,
		COPPER,
		STONE,
		OIL,
		URANIUM,
		OCEAN,
		N_RESOURCES
	};
	static const std::unordered_map<std::string, Resource::type_t> types;
	static const std::string typestr[];

	enum floodfill_flag_t
	{
		FLOODFILL_NONE,
		FLOODFILL_QUEUED
	};

	floodfill_flag_t floodfill_flag = FLOODFILL_NONE;
	
	type_t type;
	int patch_id;
	std::weak_ptr<ResourcePatch> resource_patch;
	Entity entity;

	Resource(type_t t, int parent, Entity e) : type(t), patch_id(parent), entity(e) {}
	Resource() : type(NONE), patch_id(NOT_YET_ASSIGNED), entity(Entity::nullent_tag{}) {}
};

struct ResourcePatch
{
	std::vector<Pos> positions;
	Resource::type_t type;
	int patch_id;
	Area bounding_box;

	ResourcePatch(const std::vector<Pos>& positions_, Resource::type_t t, int id) : positions(std::move(positions_)), type(t), patch_id(id)
	{
		recalc_bounding_box();
	}

	void merge_into(ResourcePatch& other)
	{
		assert(this->type == other.type);
		other.extend(this->positions);
	}

	void extend(const std::vector<Pos>& newstuff)
	{
		positions.insert(positions.end(), newstuff.begin(), newstuff.end());
		recalc_bounding_box();
	}

	bool remove(Pos pos) // FIXME slow std::find usage
	{
		auto iter = std::find(positions.begin(), positions.end(), pos);
		if (iter == positions.end())
			return false;
		unordered_erase(positions, iter);
		return true;
	}

	size_t size() const { return positions.size(); }

	private:
		void recalc_bounding_box()
		{
			bool first = true;
			for (const Pos& p : positions)
			{
				if (p.x < bounding_box.left_top.x || first)
					bounding_box.left_top.x = p.x;
				if (p.x >= bounding_box.right_bottom.x || first)
					bounding_box.right_bottom.x = p.x+1;
				if (p.y < bounding_box.left_top.y || first)
					bounding_box.left_top.y = p.y;
				if (p.y >= bounding_box.right_bottom.y || first)
					bounding_box.right_bottom.y = p.y+1;

				first = false;
			}
		}
};

