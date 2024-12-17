# GeoTracker API Documentation

## Authentication

All API requests require authentication using an API key. Include your API key in the request header:

```
X-Redmine-API-Key: your-api-key-here
```

## Endpoints

### List Locations

```
GET /api/v1/projects/:project_id/geotracker_locations
```

Parameters:
- `user_id`: Filter by user
- `issue_id`: Filter by issue
- `start_date`: Filter by start date (ISO 8601)
- `end_date`: Filter by end date (ISO 8601)
- `within_bounds`: Filter by geographical bounds (sw_lat,sw_lng,ne_lat,ne_lng)
- `limit`: Maximum number of records to return
- `offset`: Number of records to skip

### Get Single Location

```
GET /api/v1/projects/:project_id/geotracker_locations/:id
```

### Create Location

```
POST /api/v1/projects/:project_id/geotracker_locations
```

Required fields:
- `latitude`: Decimal degrees
- `longitude`: Decimal degrees

Optional fields:
- `accuracy`: Meters
- `altitude`: Meters
- `speed`: Meters per second
- `heading`: Degrees
- `activity_type`: String
- `battery_level`: Percentage
- `issue_id`: Integer
- `notes`: Text
- `metadata`: JSON object

### Batch Create Locations

```
POST /api/v1/projects/:project_id/geotracker_locations/batch_create
```

Send an array of location objects in the request body.

### Update Location

```
PUT /api/v1/projects/:project_id/geotracker_locations/:id
```

### Delete Location

```
DELETE /api/v1/projects/:project_id/geotracker_locations/:id
```

### Get Project Stats

```
GET /api/v1/projects/:project_id/geotracker_locations/stats
```

### Get Global Stats

```
GET /api/v1/geotracker/global_stats
```

## Response Formats

The API supports two response formats:

### JSON

Add `.json` to the endpoint or set `Accept: application/json` header.

Example response:
```json
{
  "id": 1,
  "type": "location",
  "attributes": {
    "latitude": 51.5074,
    "longitude": -0.1278,
    "accuracy": 10.5,
    "created_at": "2024-12-16T12:00:00Z"
  },
  "relationships": {
    "project": {
      "id": 1,
      "name": "Project Name"
    },
    "user": {
      "id": 1,
      "name": "User Name"
    }
  }
}
```

### GeoJSON

Add `.geojson` to the endpoint or set `Accept: application/geo+json` header.

Example response:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-0.1278, 51.5074]
      },
      "properties": {
        "id": 1,
        "accuracy": 10.5,
        "created_at": "2024-12-16T12:00:00Z"
      }
    }
  ]
}
```

## Error Handling

The API uses standard HTTP status codes:

- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Unprocessable Entity
- 500: Server Error

Error response format:
```json
{
  "errors": [
    {
      "field": "latitude",
      "message": "can't be blank"
    }
  ]
}
```
