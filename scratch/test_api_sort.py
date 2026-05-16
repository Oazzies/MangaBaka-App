import http.client
import json

def test_sort(sort_key):
    conn = http.client.HTTPSConnection("api.mangabaka.dev")
    url = f"/v1/series/search?sort_by={sort_key}&limit=1"
    conn.request("GET", url, headers={"User-Agent": "MangaBaka/0.1.0-pre-release-6"})
    response = conn.getresponse()
    data = response.read().decode()
    print(f"Sort Key: {sort_key}, Status: {response.status}, Body: {data[:200]}...")

test_sort("rating_desc")
test_sort("score_desc")
test_sort("weighted_score_desc")
test_sort("rating_asc")
test_sort("popularity_desc")
test_sort("name_asc")
