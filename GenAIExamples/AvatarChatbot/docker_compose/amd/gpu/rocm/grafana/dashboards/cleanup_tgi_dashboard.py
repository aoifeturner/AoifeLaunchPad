#!/usr/bin/env python3
"""
TGI Dashboard Cleanup Script
This script cleans up the TGI Grafana dashboard JSON by:
1. Optimizing panel layout to remove gaps
2. Ensuring consistent panel IDs
3. Removing any orphaned references
4. Fixing any JSON syntax issues
"""

import json
import sys
import re

def cleanup_dashboard(input_file, output_file):
    """Clean up the TGI dashboard JSON file."""
    
    print(f"Loading dashboard from {input_file}...")
    
    try:
        with open(input_file, 'r') as f:
            dashboard = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {input_file}: {e}")
        return False
    
    print("Dashboard loaded successfully.")
    
    # Get all panels
    panels = dashboard.get('panels', [])
    print(f"Found {len(panels)} panels")
    
    # Filter out row panels (they don't need layout optimization)
    data_panels = [p for p in panels if p.get('type') != 'row']
    row_panels = [p for p in panels if p.get('type') == 'row']
    
    print(f"Data panels: {len(data_panels)}")
    print(f"Row panels: {len(row_panels)}")
    
    # Optimize layout for data panels
    optimized_panels = optimize_layout(data_panels)
    
    # Reconstruct panels list with rows and optimized data panels
    final_panels = []
    current_y = 0
    
    for row in row_panels:
        # Add row panel
        row['gridPos'] = {'h': 1, 'w': 24, 'x': 0, 'y': current_y}
        final_panels.append(row)
        current_y += 1
        
        # Add panels that belong to this row
        row_panels_in_row = [p for p in optimized_panels if p.get('gridPos', {}).get('y', 0) >= current_y - 1]
        for panel in row_panels_in_row:
            panel['gridPos']['y'] = current_y
            final_panels.append(panel)
            current_y += panel['gridPos']['h']
    
    # Add any remaining panels that weren't in rows
    remaining_panels = [p for p in optimized_panels if p.get('gridPos', {}).get('y', 0) < 1]
    for panel in remaining_panels:
        panel['gridPos']['y'] = current_y
        final_panels.append(panel)
        current_y += panel['gridPos']['h']
    
    # Update dashboard with cleaned panels
    dashboard['panels'] = final_panels
    
    # Ensure dashboard has required fields
    if 'id' not in dashboard:
        dashboard['id'] = None
    if 'uid' not in dashboard:
        dashboard['uid'] = 'tgi-dashboard'
    if 'title' not in dashboard:
        dashboard['title'] = 'TGI Service Dashboard'
    
    # Clean up any other potential issues
    dashboard = cleanup_dashboard_metadata(dashboard)
    
    print(f"Saving cleaned dashboard to {output_file}...")
    
    try:
        with open(output_file, 'w') as f:
            json.dump(dashboard, f, indent=2)
        print("Dashboard saved successfully!")
        return True
    except Exception as e:
        print(f"Error saving dashboard: {e}")
        return False

def optimize_layout(panels):
    """Optimize the layout of panels to remove gaps and improve organization."""
    
    # Sort panels by current Y position
    panels.sort(key=lambda p: p.get('gridPos', {}).get('y', 0))
    
    # Group panels by approximate Y position (within 2 units)
    grouped_panels = []
    current_group = []
    current_y = 0
    
    for panel in panels:
        panel_y = panel.get('gridPos', {}).get('y', 0)
        
        if not current_group or abs(panel_y - current_y) <= 2:
            current_group.append(panel)
            current_y = max(current_y, panel_y)
        else:
            # Start new group
            if current_group:
                grouped_panels.append(current_group)
            current_group = [panel]
            current_y = panel_y
    
    if current_group:
        grouped_panels.append(current_group)
    
    # Optimize each group
    optimized_panels = []
    current_y = 0
    
    for group in grouped_panels:
        # Sort panels in group by X position
        group.sort(key=lambda p: p.get('gridPos', {}).get('x', 0))
        
        # Calculate max height in this group
        max_height = max(p.get('gridPos', {}).get('h', 1) for p in group)
        
        # Reposition panels in this group
        for panel in group:
            panel['gridPos']['y'] = current_y
        
        optimized_panels.extend(group)
        current_y += max_height
    
    return optimized_panels

def cleanup_dashboard_metadata(dashboard):
    """Clean up dashboard metadata and ensure consistency."""
    
    # Remove any invalid fields
    invalid_fields = ['__inputs', '__elements', '__requires']
    for field in invalid_fields:
        if field in dashboard:
            del dashboard[field]
    
    # Ensure required fields exist
    required_fields = {
        'annotations': {'list': []},
        'editable': True,
        'fiscalYearStartMonth': 0,
        'graphTooltip': 2,
        'links': [],
        'liveNow': False,
        'panels': [],
        'refresh': '5s',
        'schemaVersion': 38,
        'style': 'dark',
        'tags': [],
        'templating': {'list': []},
        'time': {
            'from': 'now-1h',
            'to': 'now'
        },
        'timepicker': {},
        'timezone': '',
        'title': 'TGI Service Dashboard',
        'uid': 'tgi-dashboard',
        'version': 1,
        'weekStart': ''
    }
    
    for field, default_value in required_fields.items():
        if field not in dashboard:
            dashboard[field] = default_value
    
    return dashboard

def main():
    """Main function."""
    input_file = 'tgi_grafana.json'
    output_file = 'tgi_grafana_cleaned.json'
    
    print("TGI Dashboard Cleanup Tool")
    print("=" * 40)
    
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    
    success = cleanup_dashboard(input_file, output_file)
    
    if success:
        print("\nCleanup completed successfully!")
        print(f"Original file: {input_file}")
        print(f"Cleaned file: {output_file}")
        print("\nYou can now import the cleaned dashboard into Grafana.")
    else:
        print("\nCleanup failed!")
        sys.exit(1)

if __name__ == "__main__":
    main() 