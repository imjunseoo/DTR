package com.dontori.dontori

// Widget atlas v3: full cells retain the shared (24, 47) floor anchor.
internal data class PetClip(val frames: IntArray, val durations: IntArray)
internal val petClips = mapOf(
    "seed" to mapOf(
        "idle" to PetClip(intArrayOf(R.drawable.pet_seed_idle_0, R.drawable.pet_seed_idle_1, R.drawable.pet_seed_idle_2, R.drawable.pet_seed_idle_3), intArrayOf(680, 240, 420, 240)),
        "walk_right" to PetClip(intArrayOf(R.drawable.pet_seed_walk_right_0, R.drawable.pet_seed_walk_right_1, R.drawable.pet_seed_walk_right_2, R.drawable.pet_seed_walk_right_3), intArrayOf(140, 110, 140, 110)),
        "walk_left" to PetClip(intArrayOf(R.drawable.pet_seed_walk_left_0, R.drawable.pet_seed_walk_left_1, R.drawable.pet_seed_walk_left_2, R.drawable.pet_seed_walk_left_3), intArrayOf(140, 110, 140, 110)),
        "stop" to PetClip(intArrayOf(R.drawable.pet_seed_stop_0, R.drawable.pet_seed_stop_1, R.drawable.pet_seed_stop_2), intArrayOf(120, 180, 400)),
        "rest" to PetClip(intArrayOf(R.drawable.pet_seed_rest_0, R.drawable.pet_seed_rest_1, R.drawable.pet_seed_rest_2, R.drawable.pet_seed_rest_3), intArrayOf(500, 750, 230, 400)),
        "record" to PetClip(intArrayOf(R.drawable.pet_seed_record_0, R.drawable.pet_seed_record_1, R.drawable.pet_seed_record_2, R.drawable.pet_seed_record_3, R.drawable.pet_seed_record_4, R.drawable.pet_seed_record_5), intArrayOf(150, 200, 220, 200, 220, 150)),
        "save" to PetClip(intArrayOf(R.drawable.pet_seed_save_0, R.drawable.pet_seed_save_1, R.drawable.pet_seed_save_2, R.drawable.pet_seed_save_3, R.drawable.pet_seed_save_4, R.drawable.pet_seed_save_5), intArrayOf(150, 160, 160, 200, 250, 150)),
    ),
    "sprout" to mapOf(
        "idle" to PetClip(intArrayOf(R.drawable.pet_sprout_idle_0, R.drawable.pet_sprout_idle_1, R.drawable.pet_sprout_idle_2, R.drawable.pet_sprout_idle_3), intArrayOf(680, 240, 420, 240)),
        "walk_right" to PetClip(intArrayOf(R.drawable.pet_sprout_walk_right_0, R.drawable.pet_sprout_walk_right_1, R.drawable.pet_sprout_walk_right_2, R.drawable.pet_sprout_walk_right_3), intArrayOf(140, 110, 140, 110)),
        "walk_left" to PetClip(intArrayOf(R.drawable.pet_sprout_walk_left_0, R.drawable.pet_sprout_walk_left_1, R.drawable.pet_sprout_walk_left_2, R.drawable.pet_sprout_walk_left_3), intArrayOf(140, 110, 140, 110)),
        "stop" to PetClip(intArrayOf(R.drawable.pet_sprout_stop_0, R.drawable.pet_sprout_stop_1, R.drawable.pet_sprout_stop_2), intArrayOf(120, 180, 400)),
        "rest" to PetClip(intArrayOf(R.drawable.pet_sprout_rest_0, R.drawable.pet_sprout_rest_1, R.drawable.pet_sprout_rest_2, R.drawable.pet_sprout_rest_3), intArrayOf(500, 750, 230, 400)),
        "record" to PetClip(intArrayOf(R.drawable.pet_sprout_record_0, R.drawable.pet_sprout_record_1, R.drawable.pet_sprout_record_2, R.drawable.pet_sprout_record_3, R.drawable.pet_sprout_record_4, R.drawable.pet_sprout_record_5), intArrayOf(150, 200, 220, 200, 220, 150)),
        "save" to PetClip(intArrayOf(R.drawable.pet_sprout_save_0, R.drawable.pet_sprout_save_1, R.drawable.pet_sprout_save_2, R.drawable.pet_sprout_save_3, R.drawable.pet_sprout_save_4, R.drawable.pet_sprout_save_5), intArrayOf(150, 160, 160, 200, 250, 150)),
    ),
    "bloom" to mapOf(
        "idle" to PetClip(intArrayOf(R.drawable.pet_bloom_idle_0, R.drawable.pet_bloom_idle_1, R.drawable.pet_bloom_idle_2, R.drawable.pet_bloom_idle_3), intArrayOf(680, 240, 420, 240)),
        "walk_right" to PetClip(intArrayOf(R.drawable.pet_bloom_walk_right_0, R.drawable.pet_bloom_walk_right_1, R.drawable.pet_bloom_walk_right_2, R.drawable.pet_bloom_walk_right_3), intArrayOf(140, 110, 140, 110)),
        "walk_left" to PetClip(intArrayOf(R.drawable.pet_bloom_walk_left_0, R.drawable.pet_bloom_walk_left_1, R.drawable.pet_bloom_walk_left_2, R.drawable.pet_bloom_walk_left_3), intArrayOf(140, 110, 140, 110)),
        "stop" to PetClip(intArrayOf(R.drawable.pet_bloom_stop_0, R.drawable.pet_bloom_stop_1, R.drawable.pet_bloom_stop_2), intArrayOf(120, 180, 400)),
        "rest" to PetClip(intArrayOf(R.drawable.pet_bloom_rest_0, R.drawable.pet_bloom_rest_1, R.drawable.pet_bloom_rest_2, R.drawable.pet_bloom_rest_3), intArrayOf(500, 750, 230, 400)),
        "record" to PetClip(intArrayOf(R.drawable.pet_bloom_record_0, R.drawable.pet_bloom_record_1, R.drawable.pet_bloom_record_2, R.drawable.pet_bloom_record_3, R.drawable.pet_bloom_record_4, R.drawable.pet_bloom_record_5), intArrayOf(150, 200, 220, 200, 220, 150)),
        "save" to PetClip(intArrayOf(R.drawable.pet_bloom_save_0, R.drawable.pet_bloom_save_1, R.drawable.pet_bloom_save_2, R.drawable.pet_bloom_save_3, R.drawable.pet_bloom_save_4, R.drawable.pet_bloom_save_5), intArrayOf(150, 160, 160, 200, 250, 150)),
    ),
)
