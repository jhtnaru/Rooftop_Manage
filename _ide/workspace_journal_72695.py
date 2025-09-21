# 2025-09-21T15:22:12.046549
import vitis

client = vitis.create_client()
client.set_workspace(path="Rooftop_Manage")

platform = client.get_component(name="platform_rooftop")
status = platform.build()

comp = client.get_component(name="app_rooftop")
comp.build()

vitis.dispose()

