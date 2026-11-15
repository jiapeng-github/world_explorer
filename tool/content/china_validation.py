"""Content acceptance checks for China's second editorial revision."""
import re
from collections import Counter

SECTION_IDS = {'overview', 'geography', 'people', 'daily', 'food',
               'culture', 'landmarks', 'nature', 'history', 'questions'}
LEGACY_ARTICLE_IDS = {'china-geography', 'china-nature', 'china-people',
                      'china-culture', 'china-history', 'china-explore', 'china-food'}
DIAGRAMS = {'terrain', 'paper', 'ecosystem', 'waterway', 'food', 'evidence'}


def validate_china(data):
    """Return errors; this is structural validation, not factual certification."""
    errors = []

    def check(condition, message):
        if not condition:
            errors.append(message)

    country = next((c for c in data['countries'] if c['id'] == 'china'), None)
    if country is None or country.get('revision', 1) < 2:
        return errors
    articles = [a for a in data['articles'] if a['countryId'] == 'china']
    by_id = {a['id']: a for a in articles}
    exercises = [e for e in data['exercises'] if e['countryId'] == 'china']
    by_exercise = {e['id']: e for e in exercises}
    archived = {e['id']: e for e in data.get('archivedExercises', [])}
    check(len(articles) == 30 and len(by_id) == 30, 'china: expected 30 unique articles')
    check(LEGACY_ARTICLE_IDS <= by_id.keys(), 'china: legacy article ID removed')
    check(set(country['sections']) == SECTION_IDS, 'china: section keys changed')
    assigned = [aid for ids in country['sections'].values() for aid in ids]
    check(all(len(ids) == 3 for ids in country['sections'].values()),
          'china: every section requires three primary articles')
    check(len(assigned) == 30 and len(set(assigned)) == 30 and set(assigned) == set(by_id),
          'china: section assignment must cover all articles exactly once')
    for section, ids in country['sections'].items():
        check(all(by_id.get(aid, {}).get('sectionId') == section for aid in ids),
              f'china/{section}: article assigned to the wrong primary section')
    check(Counter(e['type'] for e in exercises) == {'choice': 12, 'location': 6, 'observation': 6},
          'china: expected 12 choice, 6 location and 6 observation exercises')
    open_articles = [a for a in articles if a.get('activity', {}).get('type') == 'open']
    check(len(open_articles) == 6, 'china: expected six open activities')
    activity_ids = [a['activity'].get('id') for a in open_articles]
    check(all(activity_ids) and len(set(activity_ids)) == 6, 'china: duplicate/missing activity ID')
    used_exercises = []
    for a in articles:
        aid = a['id']
        blocks = a.get('blocks', [])
        check(4 <= len(blocks) <= 6, f'{aid}: expected 4–6 body blocks')
        count = len(re.findall(r'[\u4e00-\u9fff]', ''.join(b.get('text', '') for b in blocks)))
        check(450 <= count <= 650, f'{aid}: body must contain 450–650 Chinese characters, got {count}')
        check(a.get('characterCount') == count, f'{aid}: stale characterCount')
        check(a.get('revision') == 2, f'{aid}: missing content revision 2')
        check(a.get('diagram') in DIAGRAMS, f'{aid}: unknown diagram')
        check(1 <= len(a.get('glossary', [])) <= 4, f'{aid}: expected 1–4 glossary entries')
        check(all(g.get('term') and g.get('definition') for g in a.get('glossary', [])),
              f'{aid}: incomplete glossary')
        has_open = a.get('activity', {}).get('type') == 'open'
        has_exercise = bool(a.get('exerciseId'))
        check(has_open != has_exercise, f'{aid}: requires exactly one core activity')
        if has_open:
            activity = a['activity']
            check(bool(activity.get('prompt')) and len(activity.get('fields', [])) == 3,
                  f'{aid}: incomplete open activity')
            check(all(ref in by_id for ref in activity.get('suggestedArticleIds', [])),
                  f'{aid}: unknown suggested article')
        if has_exercise:
            used_exercises.append(a['exerciseId'])
            check(by_exercise.get(a['exerciseId'], {}).get('articleId') == aid,
                  f'{aid}: core exercise points to a different article')
    check(len(used_exercises) == 24 and len(set(used_exercises)) == 24 and
          set(used_exercises) == set(by_exercise), 'china: core exercise assignment is incomplete')
    for e in exercises:
        aid = e['articleId']
        block_ids = {b['id'] for b in by_id.get(aid, {}).get('blocks', [])}
        evidence = e.get('evidenceBlockIds', [])
        check(bool(evidence) and all(b in block_ids for b in evidence),
              f'{e["id"]}: answer requires evidence in its own article')
        if e['type'] == 'location':
            check(all(o.get('featureId') for o in e['options']), f'{e["id"]}: map options need feature IDs')
            answer = next((o for o in e['options'] if o['id'] == e['answerId']), {})
            check(answer.get('featureId') == e.get('mapFeatureId'), f'{e["id"]}: map answer mismatch')
    check('china-location' in by_exercise and 'china-canal' in by_exercise,
          'china: retained exercise IDs missing')
    check('china-transport' not in by_exercise and 'china-transport' in archived,
          'china: legacy transport question must be archived, not deleted or active')
    if 'china-transport' in archived:
        check(archived['china-transport']['articleId'] == 'china-canal-history',
              'china-transport: incorrect archived article relationship')
    return errors
