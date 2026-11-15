"""Deterministic editorial merging without mutating source records."""
from copy import deepcopy


def upsert_records(existing, incoming, *, source, kind):
    """Replace complete records by stable ID, retaining existing list order.

    Replacing a previously published record is intentional. Repeating an ID in
    either input is an editorial error, not a last-record-wins operation.
    Validation happens before any output is created.
    """
    for label, records in [('existing', existing), (source, incoming)]:
        seen = set()
        for record in records:
            identifier = record.get('id')
            if not isinstance(identifier, str) or not identifier:
                raise ValueError(f'{label}/{kind}: missing stable ID')
            if identifier in seen:
                raise ValueError(f'{label}/{kind}: duplicate ID {identifier}')
            seen.add(identifier)
    replacements = {record['id']: record for record in incoming}
    result = [deepcopy(replacements.pop(record['id'], record)) for record in existing]
    result.extend(deepcopy(record) for record in replacements.values())
    return result


def merge_country(existing, patch):
    """Preserve unpatched sections while replacing explicitly supplied lists."""
    if existing['id'] != patch['id']:
        raise ValueError('country patch ID does not match target')
    result = deepcopy(existing)
    for key, value in patch.items():
        if key in ('sections', 'editorial'):
            result[key] = {**result.get(key, {}), **deepcopy(value)}
        elif key == 'sources':
            # A revised source can update its title/checkedAt without duplicating
            # the URL in the country credits.
            sources = {s['url']: deepcopy(s) for s in result.get('sources', [])}
            sources.update({s['url']: deepcopy(s) for s in value})
            result[key] = list(sources.values())
        else:
            result[key] = deepcopy(value)
    return result


def archive_exercises(active, archived):
    """Archived questions remain addressable in migration data, not active UI."""
    archived_ids = {record['id'] for record in archived}
    return [record for record in active if record['id'] not in archived_ids]
