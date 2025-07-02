import re


def extract_left_palm_zones(text):
    match = re.search(r'Left hand palm:\s*(.*)', text)
    if match:
        zones = match.group(1).strip()
        transformed_zones = [transform_zone_name(zone.strip()) for zone in zones.split(',')]
        return transformed_zones
    return None


def extract_back_left_hand_zones(text):
    match = re.search(r'Back of left hand:\s*(.*)', text)
    if match:
        zones = match.group(1).strip()
        transformed_zones = [transform_zone_name(zone.strip()) for zone in zones.split(',')]
        return transformed_zones
    return None


def extract_seeds(text):
    match = re.search(r'Seeds to use:\s*(.*)', text)
    if match:
        seeds = match.group(1).strip()
        return [transform_zone_name(seed.strip()) for seed in seeds.split(',')]
    return None


def transform_zone_name(zone_name):
    transformed_name = zone_name.replace(' of ', ' ').replace(' ', '_').lower()
    return transformed_name
